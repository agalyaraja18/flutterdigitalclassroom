"""
URL configuration for PDF Analysis module endpoints
"""
from django.urls import path
from . import analysis_views

urlpatterns = [
    path('upload', analysis_views.upload_pdf, name='pdf-analysis-upload'),
    path('analyze', analysis_views.analyze, name='pdf-analysis-analyze'),
    path('status/<str:request_id>', analysis_views.get_status, name='pdf-analysis-status'),
    path('documents', analysis_views.list_documents, name='pdf-analysis-list-documents'),
]

