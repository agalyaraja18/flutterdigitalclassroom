from django.urls import path
from . import views

urlpatterns = [
    # Quiz creation and management (Teachers/Admins)
    path('create/', views.create_quiz, name='create_quiz'),
    path('my-quizzes/', views.list_my_quizzes, name='list_my_quizzes'),
    path('<uuid:quiz_id>/', views.quiz_detail, name='quiz_detail'),
    path('<uuid:quiz_id>/analytics/', views.quiz_analytics, name='quiz_analytics'),

    # Live quiz sessions
    path('sessions/', views.list_quiz_sessions, name='list_quiz_sessions'),
    path('sessions/completed/', views.list_completed_quiz_sessions, name='list_completed_quiz_sessions'),
    path('live/create/', views.live_create, name='live_create'),
    path('live/join/', views.live_join, name='live_join'),
    path('live/<str:room_code>/state/', views.live_state, name='live_state'),
    path('live/<str:room_code>/answer/', views.live_answer, name='live_answer'),
    path('live/<str:room_code>/next/', views.live_next, name='live_next'),
    path('live/<str:room_code>/end/', views.live_end, name='live_end'),

    # Student quiz participation
    path('join/', views.join_quiz, name='join_quiz'),
    path('session/<uuid:session_id>/', views.quiz_session, name='quiz_session'),
    path('session/<uuid:session_id>/submit/', views.submit_quiz, name='submit_quiz'),
    path('history/', views.student_quiz_history, name='student_quiz_history'),
]