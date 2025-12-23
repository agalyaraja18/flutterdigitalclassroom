from django.db import models
from django.conf import settings


class PDFDocument(models.Model):
    """Model to store uploaded PDF documents for analysis"""
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='analyzed_pdfs')
    title = models.CharField(max_length=255)
    pdf_file = models.FileField(upload_to='pdf_analyzer/')
    extracted_text = models.TextField(blank=True, help_text='Extracted text from PDF')
    upload_date = models.DateTimeField(auto_now_add=True)
    last_queried = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    
    class Meta:
        ordering = ['-upload_date']
        verbose_name = 'PDF Document'
        verbose_name_plural = 'PDF Documents'
    
    def __str__(self):
        return f"{self.title} - {self.uploaded_by.username}"


class ChatSession(models.Model):
    """Model to store chat sessions for a PDF document"""
    pdf_document = models.ForeignKey(PDFDocument, on_delete=models.CASCADE, related_name='chat_sessions')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    session_id = models.CharField(max_length=100, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Chat Session for {self.pdf_document.title} - {self.session_id}"


class ChatMessage(models.Model):
    """Model to store individual chat messages"""
    MESSAGE_TYPES = (
        ('user', 'User'),
        ('ai', 'AI'),
    )
    
    chat_session = models.ForeignKey(ChatSession, on_delete=models.CASCADE, related_name='messages')
    message_type = models.CharField(max_length=10, choices=MESSAGE_TYPES)
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['timestamp']
    
    def __str__(self):
        return f"{self.message_type}: {self.content[:50]}..."


# New models for PDF Analysis module (spec-compliant)
class AnalysisDocument(models.Model):
    """Model to store uploaded PDF documents for the new PDF Analysis module"""
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='analysis_documents')
    file_id = models.CharField(max_length=100, unique=True, db_index=True)
    pdf_file = models.FileField(upload_to='pdf_analysis/temp/')
    metadata = models.JSONField(default=dict, blank=True)
    extracted_text = models.TextField(blank=True)
    page_count = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)  # For temporary storage retention
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Analysis Document'
        verbose_name_plural = 'Analysis Documents'
    
    def __str__(self):
        return f"Analysis Document {self.file_id} - {self.uploaded_by.username}"


class AnalysisRequest(models.Model):
    """Model to track analysis requests (summarize, explain, answer)"""
    STATUS_CHOICES = [
        ('queued', 'Queued'),
        ('processing', 'Processing'),
        ('done', 'Done'),
        ('error', 'Error'),
    ]
    
    TASK_CHOICES = [
        ('summarize', 'Summarize'),
        ('explain', 'Explain'),
        ('answer', 'Answer'),
    ]
    
    request_id = models.CharField(max_length=100, unique=True, db_index=True)
    document = models.ForeignKey(AnalysisDocument, on_delete=models.CASCADE, related_name='analysis_requests')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    task = models.CharField(max_length=20, choices=TASK_CHOICES)
    task_options = models.JSONField(default=dict)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='queued')
    result = models.JSONField(null=True, blank=True)
    error = models.TextField(null=True, blank=True)
    model_used = models.CharField(max_length=100, blank=True)
    cost_estimate = models.FloatField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Analysis Request {self.request_id} - {self.task} - {self.status}"
