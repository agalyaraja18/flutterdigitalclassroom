from rest_framework import serializers
from .models import PDFDocument

class PDFDocumentSerializer(serializers.ModelSerializer):
    uploaded_by = serializers.StringRelatedField(read_only=True)

    class Meta:
        model = PDFDocument
        fields = ['id', 'title', 'pdf_file', 'audio_file', 'uploaded_by', 'conversion_status', 'created_at', 'updated_at']
        read_only_fields = ['id', 'audio_file', 'uploaded_by', 'conversion_status', 'created_at', 'updated_at']

class PDFUploadSerializer(serializers.ModelSerializer):
    class Meta:
        model = PDFDocument
        fields = ['title', 'pdf_file']

    def validate_pdf_file(self, value):
        if not value.name.endswith('.pdf'):
            raise serializers.ValidationError("Only PDF files are allowed.")
        if value.size > 10 * 1024 * 1024:  # 10MB limit
            raise serializers.ValidationError("File size cannot exceed 10MB.")
        return value