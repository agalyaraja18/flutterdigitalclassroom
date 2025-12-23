"""
Views for PDF Analysis module - spec-compliant endpoints
"""
import uuid
import threading
import json
from datetime import timedelta
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import AnalysisDocument, AnalysisRequest
from .serializers import (
    AnalysisDocumentUploadSerializer,
    AnalysisRequestSerializer,
    AnalysisDocumentSerializer,
    AnalysisRequestResponseSerializer,
    AnalysisStatusSerializer
)
from .analysis_service import get_analysis_service


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upload_pdf(request):
    """
    Upload PDF file. Returns a file_id to be used for question calls.
    POST /api/pdf-analysis/upload
    """
    # Handle multipart form data
    if 'file' not in request.FILES:
        return Response(
            {'error': 'file field is required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    pdf_file = request.FILES['file']
    metadata_str = request.POST.get('metadata', '{}')
    
    try:
        metadata = json.loads(metadata_str) if metadata_str else {}
    except json.JSONDecodeError:
        metadata = {}
    
    # Validate using serializer
    serializer = AnalysisDocumentUploadSerializer(data={
        'file': pdf_file,
        'metadata': metadata
    })
    
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # Generate unique file_id
        file_id = str(uuid.uuid4())
        
        # Extract text and get page count
        analysis_service = get_analysis_service()
        if analysis_service is None:
            return Response(
                {'error': 'AI service not available. Please configure AI_API_KEY.'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )
        
        # Extract text from PDF
        pages, page_count = analysis_service.extract_text_from_pdf(pdf_file)
        extracted_text = '\n\n'.join([f"Page {p['page']}:\n{p['text']}" for p in pages])
        
        # Calculate expiration time (1 hour retention as per spec)
        expires_at = timezone.now() + timedelta(seconds=3600)
        
        # Create document record
        document = AnalysisDocument.objects.create(
            uploaded_by=request.user,
            file_id=file_id,
            pdf_file=pdf_file,
            metadata=metadata,
            extracted_text=extracted_text,
            page_count=page_count,
            expires_at=expires_at
        )
        
        # Serialize the document for response
        document_serializer = AnalysisDocumentSerializer(document)
        
        return Response({
            'file_id': file_id,
            'status': 'success',
            'message': 'PDF uploaded successfully',
            'pdf_document': document_serializer.data,
            'session_id': file_id  # For compatibility with Flutter app
        }, status=status.HTTP_201_CREATED)
    
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


def process_analysis_request(request_id):
    """Background task to process analysis request"""
    try:
        analysis_request = AnalysisRequest.objects.get(request_id=request_id)
        analysis_request.status = 'processing'
        analysis_request.save()
        
        # Get the document
        document = analysis_request.document
        
        # Get analysis service
        analysis_service = get_analysis_service()
        if analysis_service is None:
            analysis_request.status = 'error'
            analysis_request.error = 'AI service not available'
            analysis_request.save()
            return
        
        # Get task and options
        task = analysis_request.task
        task_options = analysis_request.task_options.copy()  # Make a copy to avoid modifying stored data
        # response_format is stored in task_options for backward compatibility
        response_format = task_options.pop('response_format', 'text')
        
        # Analyze the content
        result = analysis_service.analyze_content(
            task=task,
            task_options=task_options,
            pdf_content=document.extracted_text,
            response_format=response_format
        )
        
        # Estimate cost (simplified - in production, track actual token usage)
        cost_estimate = None  # Could be calculated based on token usage
        
        # Update request
        analysis_request.status = 'done'
        analysis_request.result = result
        analysis_request.model_used = analysis_service.model_name
        analysis_request.cost_estimate = cost_estimate
        analysis_request.save()
    
    except AnalysisRequest.DoesNotExist:
        pass
    except Exception as e:
        try:
            analysis_request.status = 'error'
            analysis_request.error = str(e)
            analysis_request.save()
        except Exception:
            pass


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def analyze(request):
    """
    Ask a question or request a task (summary/explain/qa) about a previously uploaded PDF.
    POST /api/pdf-analysis/analyze
    """
    # Handle JSON data
    if request.content_type != 'application/json':
        # Try to parse as JSON anyway
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return Response(
                {'error': 'Request must be JSON'},
                status=status.HTTP_400_BAD_REQUEST
            )
    else:
        data = request.data
    
    serializer = AnalysisRequestSerializer(data=data)
    
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    file_id = serializer.validated_data['file_id']
    task = serializer.validated_data['task']
    task_options = serializer.validated_data.get('task_options', {})
    response_format = serializer.validated_data.get('response_format', 'text')
    
    # Store response_format separately (not in task_options) for clarity
    # We'll pass it separately to the processing function
    
    try:
        # Get the document
        document = AnalysisDocument.objects.get(
            file_id=file_id,
            uploaded_by=request.user
        )
        
        # Check if document has expired
        if document.expires_at and document.expires_at < timezone.now():
            return Response(
                {'error': 'Document has expired'},
                status=status.HTTP_410_GONE
            )
        
        # Generate unique request_id
        request_id = str(uuid.uuid4())
        
        # Store response_format in task_options for processing
        task_options_with_format = task_options.copy()
        task_options_with_format['response_format'] = response_format
        
        # Create analysis request
        analysis_request = AnalysisRequest.objects.create(
            request_id=request_id,
            document=document,
            user=request.user,
            task=task,
            task_options=task_options_with_format,
            status='queued'
        )
        
        # Start background processing
        thread = threading.Thread(target=process_analysis_request, args=(request_id,))
        thread.daemon = True
        thread.start()
        
        # Return immediate response (matches spec response_schema)
        return Response({
            'request_id': request_id,
            'status': 'queued',
            'result': None,
            'model_used': None,
            'cost_estimate': None
        }, status=status.HTTP_202_ACCEPTED)
    
    except AnalysisDocument.DoesNotExist:
        return Response(
            {'error': 'Document not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_status(request, request_id):
    """
    Get status and result for an analyze request.
    GET /api/pdf-analysis/status/{request_id}
    """
    try:
        analysis_request = AnalysisRequest.objects.get(
            request_id=request_id,
            user=request.user
        )
        
        serializer = AnalysisStatusSerializer(analysis_request)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    except AnalysisRequest.DoesNotExist:
        return Response(
            {'error': 'Request not found'},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_documents(request):
    """
    List all uploaded PDF documents for the current user.
    GET /api/pdf-analysis/documents
    """
    try:
        documents = AnalysisDocument.objects.filter(
            uploaded_by=request.user
        ).order_by('-created_at')
        
        serializer = AnalysisDocumentSerializer(documents, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

