from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.shortcuts import get_object_or_404
from .models import PDFDocument
from .serializers import PDFDocumentSerializer, PDFUploadSerializer
from .utils import process_pdf_to_audio
import threading

# For analyzer session creation so the converter document detail can return
# an analyzer session when requested by the frontend (makes documents
# immediately queryable).
try:
    from apps.pdf_analyzer.services import gemini_service
    from apps.pdf_analyzer.models import ChatSession, ChatMessage
except Exception:
    gemini_service = None
    ChatSession = None
    ChatMessage = None

class StandardResultsSetPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upload_pdf(request):
    """Upload a PDF file for conversion"""
    serializer = PDFUploadSerializer(data=request.data)
    if serializer.is_valid():
        pdf_document = serializer.save(uploaded_by=request.user)

        # Start conversion in background thread
        def convert_in_background():
            try:
                process_pdf_to_audio(pdf_document)
            except Exception as e:
                print(f"Conversion failed for document {pdf_document.id}: {str(e)}")

        thread = threading.Thread(target=convert_in_background)
        thread.start()

        return Response(
            PDFDocumentSerializer(pdf_document).data,
            status=status.HTTP_201_CREATED
        )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_documents(request):
    """List all PDF documents for the authenticated user"""
    if request.user.user_type == 'admin':
        documents = PDFDocument.objects.all()
    else:
        documents = PDFDocument.objects.filter(uploaded_by=request.user)

    paginator = StandardResultsSetPagination()
    page = paginator.paginate_queryset(documents, request)
    if page is not None:
        serializer = PDFDocumentSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)

    serializer = PDFDocumentSerializer(documents, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_document(request, document_id):
    """Get details of a specific PDF document"""
    if request.user.user_type == 'admin':
        document = get_object_or_404(PDFDocument, id=document_id)
    else:
        document = get_object_or_404(PDFDocument, id=document_id, uploaded_by=request.user)

    # Build base response
    resp_data = PDFDocumentSerializer(document).data

    # If analyzer services are available, ensure a chat session exists and
    # include it in the response so the client can begin querying immediately.
    if gemini_service is not None and ChatSession is not None:
        try:
            existing = ChatSession.objects.filter(pdf_document__id=document.id, user=request.user).order_by('-created_at').first()
            if existing is None:
                # create session on-demand
                session_id = gemini_service.generate_session_id()
                chat_response = gemini_service.initialize_chat_session(session_id, document.extracted_text or '')

                existing = ChatSession.objects.create(
                    pdf_document=document,
                    user=request.user,
                    session_id=session_id
                )

                initial_text = chat_response.get('initial_response') if isinstance(chat_response, dict) else None
                if initial_text and ChatMessage is not None:
                    ChatMessage.objects.create(
                        chat_session=existing,
                        message_type='ai',
                        content=initial_text
                    )

            # attach serialized session info
            try:
                from apps.pdf_analyzer.serializers import ChatSessionSerializer
                resp_data = {
                    'pdf_document': resp_data,
                    'session': ChatSessionSerializer(existing).data,
                    'session_id': existing.session_id
                }
            except Exception:
                # If serializer import fails, fall back to returning only document
                pass
        except Exception:
            # best-effort: ignore analyzer creation errors
            pass

    return Response(resp_data)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_document(request, document_id):
    """Delete a PDF document"""
    if request.user.user_type == 'admin':
        document = get_object_or_404(PDFDocument, id=document_id)
    else:
        document = get_object_or_404(PDFDocument, id=document_id, uploaded_by=request.user)

    # Delete associated files
    if document.pdf_file:
        document.pdf_file.delete()
    if document.audio_file:
        document.audio_file.delete()

    document.delete()
    return Response({'message': 'Document deleted successfully'}, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def retry_conversion(request, document_id):
    """Retry conversion for a failed document"""
    if request.user.user_type == 'admin':
        document = get_object_or_404(PDFDocument, id=document_id)
    else:
        document = get_object_or_404(PDFDocument, id=document_id, uploaded_by=request.user)

    if document.conversion_status != 'failed':
        return Response(
            {'error': 'Can only retry failed conversions'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Reset status and retry conversion
    document.conversion_status = 'pending'
    document.save()

    def convert_in_background():
        try:
            process_pdf_to_audio(document)
        except Exception as e:
            print(f"Retry conversion failed for document {document.id}: {str(e)}")

    thread = threading.Thread(target=convert_in_background)
    thread.start()

    return Response(
        PDFDocumentSerializer(document).data,
        status=status.HTTP_200_OK
    )