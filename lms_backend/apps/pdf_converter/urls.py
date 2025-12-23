from django.urls import path
from . import views

urlpatterns = [
    path('upload/', views.upload_pdf, name='upload_pdf'),
    path('documents/', views.list_documents, name='list_documents'),
    path('documents/<int:document_id>/', views.get_document, name='get_document'),
    path('documents/<int:document_id>/delete/', views.delete_document, name='delete_document'),
    path('documents/<int:document_id>/retry/', views.retry_conversion, name='retry_conversion'),
]