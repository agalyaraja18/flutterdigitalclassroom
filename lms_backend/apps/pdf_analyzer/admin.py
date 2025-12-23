from django.contrib import admin
from .models import PDFDocument, ChatSession, ChatMessage, AnalysisDocument, AnalysisRequest


@admin.register(PDFDocument)
class PDFDocumentAdmin(admin.ModelAdmin):
    list_display = ['title', 'uploaded_by', 'upload_date', 'last_queried', 'is_active']
    list_filter = ['is_active', 'upload_date']
    search_fields = ['title', 'uploaded_by__username']
    readonly_fields = ['upload_date', 'last_queried']


@admin.register(ChatSession)
class ChatSessionAdmin(admin.ModelAdmin):
    list_display = ['session_id', 'pdf_document', 'user', 'created_at', 'is_active']
    list_filter = ['is_active', 'created_at']
    search_fields = ['session_id', 'user__username', 'pdf_document__title']
    readonly_fields = ['session_id', 'created_at', 'updated_at']


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = ['chat_session', 'message_type', 'content_preview', 'timestamp']
    list_filter = ['message_type', 'timestamp']
    search_fields = ['content']
    readonly_fields = ['timestamp']
    
    def content_preview(self, obj):
        return obj.content[:100] + '...' if len(obj.content) > 100 else obj.content
    content_preview.short_description = 'Content'


# Admin for new PDF Analysis module models
@admin.register(AnalysisDocument)
class AnalysisDocumentAdmin(admin.ModelAdmin):
    list_display = ['file_id', 'uploaded_by', 'page_count', 'created_at', 'expires_at']
    list_filter = ['created_at', 'expires_at']
    search_fields = ['file_id', 'uploaded_by__username']
    readonly_fields = ['file_id', 'created_at']
    date_hierarchy = 'created_at'


@admin.register(AnalysisRequest)
class AnalysisRequestAdmin(admin.ModelAdmin):
    list_display = ['request_id', 'document', 'user', 'task', 'status', 'created_at', 'updated_at']
    list_filter = ['status', 'task', 'created_at']
    search_fields = ['request_id', 'user__username', 'document__file_id']
    readonly_fields = ['request_id', 'created_at', 'updated_at']
    date_hierarchy = 'created_at'
