from rest_framework import serializers
from .models import PDFDocument, ChatSession, ChatMessage, AnalysisDocument, AnalysisRequest


class PDFDocumentSerializer(serializers.ModelSerializer):
    uploaded_by_username = serializers.CharField(source='uploaded_by.username', read_only=True)
    session_id = serializers.SerializerMethodField()

    class Meta:
        model = PDFDocument
        fields = ['id', 'title', 'pdf_file', 'upload_date', 'last_queried',
                  'uploaded_by_username', 'is_active', 'session_id']
        read_only_fields = ['id', 'upload_date', 'last_queried', 'uploaded_by_username', 'session_id']

    def get_session_id(self, obj):
        """Get the session_id of the most recent chat session for this PDF"""
        latest_session = obj.chat_sessions.filter(is_active=True).order_by('-created_at').first()
        return latest_session.session_id if latest_session else None


class ChatMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatMessage
        fields = ['id', 'message_type', 'content', 'timestamp']
        read_only_fields = ['id', 'timestamp']


class ChatSessionSerializer(serializers.ModelSerializer):
    messages = ChatMessageSerializer(many=True, read_only=True)
    pdf_title = serializers.CharField(source='pdf_document.title', read_only=True)
    
    class Meta:
        model = ChatSession
        fields = ['id', 'session_id', 'pdf_document', 'pdf_title', 
                  'created_at', 'updated_at', 'is_active', 'messages']
        read_only_fields = ['id', 'session_id', 'created_at', 'updated_at']


class PDFUploadSerializer(serializers.Serializer):
    """Serializer for PDF upload"""
    title = serializers.CharField(max_length=255)
    pdf_file = serializers.FileField()
    
    def validate_pdf_file(self, value):
        if not value.name.endswith('.pdf'):
            raise serializers.ValidationError("Only PDF files are allowed")
        
        # Check file size (max 10MB)
        if value.size > 10 * 1024 * 1024:
            raise serializers.ValidationError("File size should not exceed 10MB")
        
        return value


class QuerySerializer(serializers.Serializer):
    """Serializer for PDF query requests"""
    session_id = serializers.CharField()
    query = serializers.CharField()


class QueryResponseSerializer(serializers.Serializer):
    """Serializer for query responses"""
    query = serializers.CharField()
    response = serializers.CharField()
    timestamp = serializers.DateTimeField()


# New serializers for PDF Analysis module (spec-compliant)
class AnalysisDocumentUploadSerializer(serializers.Serializer):
    """Serializer for PDF upload in PDF Analysis module"""
    file = serializers.FileField()
    metadata = serializers.JSONField(required=False, allow_null=True)
    
    def validate_file(self, value):
        if not value.name.endswith('.pdf'):
            raise serializers.ValidationError("Only PDF files are allowed")
        
        # Check file size (max 50MB as per spec)
        max_size = 52428800  # 50MB in bytes
        if value.size > max_size:
            raise serializers.ValidationError(f"File size should not exceed {max_size / 1024 / 1024}MB")
        
        return value


class AnalysisRequestSerializer(serializers.Serializer):
    """Serializer for analysis request"""
    file_id = serializers.CharField(required=True)
    task = serializers.ChoiceField(choices=['summarize', 'explain', 'answer'], required=True)
    task_options = serializers.JSONField(required=False, default=dict)
    response_format = serializers.ChoiceField(choices=['text', 'json', 'bulleted'], required=False, default='text')
    
    def validate(self, attrs):
        task = attrs.get('task')
        task_options = attrs.get('task_options', {})
        
        if task == 'explain' and not task_options.get('explain_topic'):
            raise serializers.ValidationError("explain_topic is required when task is 'explain'")
        
        if task == 'answer' and not task_options.get('question'):
            raise serializers.ValidationError("question is required when task is 'answer'")
        
        if task == 'summarize' and 'summarize_length' in task_options:
            length = task_options['summarize_length']
            if length not in ['short', 'medium', 'long']:
                raise serializers.ValidationError("summarize_length must be 'short', 'medium', or 'long'")
        
        return attrs


class AnalysisDocumentSerializer(serializers.ModelSerializer):
    """Serializer for AnalysisDocument"""
    uploaded_by_username = serializers.CharField(source='uploaded_by.username', read_only=True)
    title = serializers.SerializerMethodField()
    upload_date = serializers.DateTimeField(source='created_at', read_only=True)
    is_active = serializers.SerializerMethodField()
    session_id = serializers.CharField(source='file_id', read_only=True)
    
    class Meta:
        model = AnalysisDocument
        fields = ['id', 'file_id', 'title', 'pdf_file', 'metadata', 'page_count', 
                  'created_at', 'upload_date', 'uploaded_by_username', 'is_active', 'session_id']
        read_only_fields = ['id', 'file_id', 'page_count', 'created_at', 'upload_date']
    
    def get_title(self, obj):
        """Extract title from metadata or use filename"""
        if obj.metadata and 'title' in obj.metadata:
            return obj.metadata['title']
        # Extract filename from pdf_file path
        if obj.pdf_file:
            return obj.pdf_file.name.split('/')[-1].replace('.pdf', '')
        return f"Document {obj.file_id[:8]}"
    
    def get_is_active(self, obj):
        """Check if document is still active (not expired)"""
        from django.utils import timezone
        if obj.expires_at:
            return timezone.now() < obj.expires_at
        return True


class AnalysisRequestResponseSerializer(serializers.ModelSerializer):
    """Serializer for analysis request response"""
    class Meta:
        model = AnalysisRequest
        fields = ['request_id', 'status', 'result', 'model_used', 'cost_estimate', 'error', 'created_at', 'updated_at']
        read_only_fields = ['request_id', 'status', 'result', 'model_used', 'cost_estimate', 'error', 'created_at', 'updated_at']


class AnalysisStatusSerializer(serializers.ModelSerializer):
    """Serializer for analysis status response"""
    class Meta:
        model = AnalysisRequest
        fields = ['request_id', 'status', 'result', 'error']
        read_only_fields = ['request_id', 'status', 'result', 'error']
