"""
URL configuration for lms_backend project.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse

def api_root(request):
    """API root endpoint providing documentation of all available endpoints"""
    return JsonResponse({
        'message': 'LMS Backend API',
        'version': '1.0',
        'documentation': {
            'authentication': {
                'base_url': '/api/auth/',
                'endpoints': {
                    'register': {'method': 'POST', 'url': '/api/auth/register/', 'description': 'Register a new user'},
                    'login': {'method': 'POST', 'url': '/api/auth/login/', 'description': 'Login and get authentication token'},
                    'logout': {'method': 'POST', 'url': '/api/auth/logout/', 'description': 'Logout user'},
                    'profile': {'method': 'GET', 'url': '/api/auth/profile/', 'description': 'Get current user profile'},
                    'users': {'method': 'GET', 'url': '/api/auth/users/', 'description': 'List all users (admin)'}
                }
            },
            'pdf_converter': {
                'base_url': '/api/pdf/',
                'endpoints': {
                    'upload': {'method': 'POST', 'url': '/api/pdf/upload/', 'description': 'Upload PDF for audio conversion'},
                    'documents': {'method': 'GET', 'url': '/api/pdf/documents/', 'description': 'List all PDF documents'},
                    'document_detail': {'method': 'GET', 'url': '/api/pdf/documents/<id>/', 'description': 'Get document details'},
                    'delete_document': {'method': 'DELETE', 'url': '/api/pdf/documents/<id>/delete/', 'description': 'Delete a document'},
                    'retry_conversion': {'method': 'POST', 'url': '/api/pdf/documents/<id>/retry/', 'description': 'Retry PDF conversion'}
                }
            },
            'quiz_system': {
                'base_url': '/api/quiz/',
                'endpoints': {
                    'create_quiz': {'method': 'POST', 'url': '/api/quiz/create/', 'description': 'Create a new quiz (teacher/admin)'},
                    'my_quizzes': {'method': 'GET', 'url': '/api/quiz/my-quizzes/', 'description': 'List my quizzes (teacher/admin)'},
                    'quiz_detail': {'method': 'GET', 'url': '/api/quiz/<uuid>/', 'description': 'Get quiz details'},
                    'quiz_analytics': {'method': 'GET', 'url': '/api/quiz/<uuid>/analytics/', 'description': 'Get quiz analytics'},
                    'join_quiz': {'method': 'POST', 'url': '/api/quiz/join/', 'description': 'Join a quiz session'},
                    'quiz_session': {'method': 'GET', 'url': '/api/quiz/session/<uuid>/', 'description': 'Get quiz session details'},
                    'submit_quiz': {'method': 'POST', 'url': '/api/quiz/session/<uuid>/submit/', 'description': 'Submit quiz answers'},
                    'quiz_history': {'method': 'GET', 'url': '/api/quiz/history/', 'description': 'Get student quiz history'},
                    'list_sessions': {'method': 'GET', 'url': '/api/quiz/sessions/', 'description': 'List quiz sessions'},
                    'completed_sessions': {'method': 'GET', 'url': '/api/quiz/sessions/completed/', 'description': 'List completed sessions'}
                }
            },
            'pdf_analysis': {
                'base_url': '/api/pdf-analysis/',
                'endpoints': {
                    'upload': {'method': 'POST', 'url': '/api/pdf-analysis/upload', 'description': 'Upload PDF file. Returns a file_id to be used for question calls.'},
                    'analyze': {'method': 'POST', 'url': '/api/pdf-analysis/analyze', 'description': 'Ask a question or request a task (summary/explain/qa) about a previously uploaded PDF.'},
                    'status': {'method': 'GET', 'url': '/api/pdf-analysis/status/<request_id>', 'description': 'Get status and result for an analyze request.'},
                    'documents': {'method': 'GET', 'url': '/api/pdf-analysis/documents', 'description': 'List all uploaded PDF documents for the current user.'}
                }
            },
            'admin': {
                'base_url': '/admin/',
                'description': 'Django admin interface'
            }
        }
    })

urlpatterns = [
    path('', api_root, name='api_root'),
    path('admin/', admin.site.urls),
    path('api/auth/', include('apps.authentication.urls')),
    path('api/pdf/', include('apps.pdf_converter.urls')),
    path('api/quiz/', include('apps.quiz_system.urls')),
    path('api/pdf-analysis/', include('apps.pdf_analyzer.analysis_urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)