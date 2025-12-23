from django.contrib import admin
from .models import PDFDocument

@admin.register(PDFDocument)
class PDFDocumentAdmin(admin.ModelAdmin):
    list_display = ['title', 'uploaded_by', 'conversion_status', 'created_at']
    list_filter = ['conversion_status', 'created_at', 'uploaded_by__user_type']
    search_fields = ['title', 'uploaded_by__username']
    readonly_fields = ['text_content', 'created_at', 'updated_at']

    fieldsets = (
        ('Document Info', {
            'fields': ('title', 'uploaded_by', 'pdf_file')
        }),
        ('Conversion', {
            'fields': ('conversion_status', 'audio_file', 'text_content')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )