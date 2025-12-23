from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.db.models import Count, Avg
from .models import Quiz, Question, Choice, QuizSession, Answer, LiveQuizSession, LiveParticipant
from .serializers import (
    QuizSerializer, QuizDetailSerializer, QuizCreateSerializer,
    QuizSessionSerializer, AnswerSubmissionSerializer, QuizJoinSerializer,
    QuizResultSerializer, LiveSessionCreateSerializer, LiveSessionStateSerializer,
    QuestionSerializer
)
from .utils import create_quiz_from_ai, calculate_quiz_score
import threading
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model
from django.utils.crypto import get_random_string

class StandardResultsSetPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100

# Quiz Management Views (for Teachers/Admins)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_quiz(request):
    """Create a new quiz using AI generation"""
    if request.user.user_type not in ['teacher', 'admin']:
        return Response({'error': 'Only teachers and admins can create quizzes'},
                       status=status.HTTP_403_FORBIDDEN)

    serializer = QuizCreateSerializer(data=request.data)
    if serializer.is_valid():
        try:
            def create_quiz_async():
                return create_quiz_from_ai(
                    title=serializer.validated_data['title'],
                    topic=serializer.validated_data['topic'],
                    difficulty=serializer.validated_data['difficulty'],
                    num_questions=serializer.validated_data['number_of_questions'],
                    created_by=request.user,
                    time_limit=serializer.validated_data.get('time_limit', 30)
                )

            # For now, create synchronously. In production, use Celery for async processing
            quiz = create_quiz_async()

            # Create response with quiz data and include both quiz_code and room_code
            # so frontends can read either key reliably.
            response_data = QuizSerializer(quiz).data
            response_data['quiz_code'] = quiz.quiz_code
            response_data['room_code'] = quiz.quiz_code

            return Response(
                response_data,
                status=status.HTTP_201_CREATED
            )
        except Exception as e:
            return Response(
                {'error': f'Failed to create quiz: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST
            )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_my_quizzes(request):
    """List quizzes created by the current teacher"""
    if request.user.user_type not in ['teacher', 'admin']:
        return Response({'error': 'Only teachers and admins can view created quizzes'},
                       status=status.HTTP_403_FORBIDDEN)

    if request.user.user_type == 'admin':
        quizzes = Quiz.objects.all()
    else:
        quizzes = Quiz.objects.filter(created_by=request.user)

    paginator = StandardResultsSetPagination()
    page = paginator.paginate_queryset(quizzes, request)
    if page is not None:
        serializer = QuizSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)

    serializer = QuizSerializer(quizzes, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def quiz_detail(request, quiz_id):
    """Get detailed quiz information"""
    quiz = get_object_or_404(Quiz, id=quiz_id)

    # Check permissions
    if request.user.user_type == 'student':
        # Students can only see basic info and questions if they have an active session
        try:
            session = QuizSession.objects.get(quiz=quiz, student=request.user, status='started')
            serializer = QuizDetailSerializer(quiz)
        except QuizSession.DoesNotExist:
            serializer = QuizSerializer(quiz)
    else:
        # Teachers and admins can see full details
        if quiz.created_by != request.user and request.user.user_type != 'admin':
            return Response({'error': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
        serializer = QuizDetailSerializer(quiz)

    return Response(serializer.data)

# Student Quiz Views

@api_view(['POST'])
@permission_classes([AllowAny])
def join_quiz(request):
    """Join a quiz using quiz code"""
    # Resolve user: prefer DRF-authenticated user; otherwise accept token in payload
    user = None
    if request.user and request.user.is_authenticated:
        user = request.user
    else:
        token_key = request.data.get('token')
        # Also try Authorization header if present
        auth_header = request.META.get('HTTP_AUTHORIZATION')
        if not token_key and auth_header and auth_header.startswith('Token '):
            token_key = auth_header.split(' ', 1)[1]
        if token_key:
            try:
                user = Token.objects.get(key=token_key).user
            except Token.DoesNotExist:
                user = None

    created_guest = False
    guest_token = None
    if not user:
        # Create a temporary guest student user
        User = get_user_model()
        # Generate a unique guest username
        for _ in range(5):
            username = f"guest_{get_random_string(8).lower()}"
            if not User.objects.filter(username=username).exists():
                break
        user = User.objects.create_user(
            username=username,
            password=get_random_string(16),
            user_type='student'
        )
        token_obj, _ = Token.objects.get_or_create(user=user)
        guest_token = token_obj.key
        created_guest = True

    print(f"JOIN QUIZ DEBUG: User={user}, UserType={getattr(user, 'user_type', None)}, Data={request.data}")

    if getattr(user, 'user_type', None) != 'student':
        return Response({'error': 'Only students can join quizzes'},
                        status=status.HTTP_403_FORBIDDEN)

    serializer = QuizJoinSerializer(data=request.data)
    if serializer.is_valid():
        quiz_code = serializer.validated_data['quiz_code']

        # First try to find quiz by quiz_code (regular quiz)
        quiz = None
        try:
            quiz = Quiz.objects.get(quiz_code=quiz_code, is_active=True)
        except Quiz.DoesNotExist:
            # If not found, try to find by room_code (live session)
            try:
                live_session = LiveQuizSession.objects.get(room_code=quiz_code, is_active=True)
                quiz = live_session.quiz
            except LiveQuizSession.DoesNotExist:
                return Response({'error': 'Invalid or inactive quiz code'},
                               status=status.HTTP_400_BAD_REQUEST)

        # Check if student already has a session for this quiz
        existing_session = QuizSession.objects.filter(quiz=quiz, student=user).first()
        if existing_session:
            if existing_session.status == 'completed':
                return Response({'error': 'You have already completed this quiz'},
                               status=status.HTTP_400_BAD_REQUEST)
            else:
                # Return existing session (include guest token if one was created just now)
                payload = QuizSessionSerializer(existing_session).data
                if guest_token:
                    payload = { 'session': payload, 'token': guest_token }
                return Response(payload)

        # Create new session
        session = QuizSession.objects.create(
            quiz=quiz,
            student=user,
            status='started'
        )

        payload = QuizSessionSerializer(session).data
        if guest_token:
            payload = { 'session': payload, 'token': guest_token }
        return Response(payload, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def quiz_session(request, session_id):
    """Get quiz session details"""
    session = get_object_or_404(QuizSession, id=session_id, student=request.user)

    if session.status == 'completed':
        # Show results with correct answers
        quiz_data = QuizResultSerializer(session.quiz).data
        session_data = QuizSessionSerializer(session).data

        # Add user's answers to the response
        user_answers = {}
        for answer in session.answers.all():
            user_answers[str(answer.question.id)] = {
                'selected_choice': answer.selected_choice.id if answer.selected_choice else None,
                'text_answer': answer.text_answer,
                'is_correct': answer.is_correct,
                'points_earned': answer.points_earned
            }

        return Response({
            'session': session_data,
            'quiz': quiz_data,
            'user_answers': user_answers
        })
    else:
        # Show quiz for taking
        serializer = QuizDetailSerializer(session.quiz)
        return Response({
            'session': QuizSessionSerializer(session).data,
            'quiz': serializer.data
        })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def submit_quiz(request, session_id):
    """Submit quiz answers"""
    session = get_object_or_404(QuizSession, id=session_id, student=request.user)

    if session.status != 'started':
        return Response({'error': 'Quiz session is not active'},
                       status=status.HTTP_400_BAD_REQUEST)

    serializer = AnswerSubmissionSerializer(data=request.data)
    if serializer.is_valid():
        answers_data = serializer.validated_data['answers']

        # Save answers
        for answer_data in answers_data:
            question = get_object_or_404(Question, id=answer_data['question'], quiz=session.quiz)

            # Resolve selected_choice to object (and ensure it belongs to the same question)
            selected_choice_obj = None
            selected_choice_id = answer_data.get('selected_choice')
            if selected_choice_id is not None:
                selected_choice_obj = get_object_or_404(Choice, id=selected_choice_id, question=question)

            # Check if answer already exists (prevent duplicate submission)
            answer, created = Answer.objects.get_or_create(
                session=session,
                question=question,
                defaults={
                    'selected_choice': selected_choice_obj,
                    'text_answer': answer_data.get('text_answer', ''),
                }
            )

            if not created:
                # Update existing answer
                answer.selected_choice = selected_choice_obj
                answer.text_answer = answer_data.get('text_answer', '')

            # Check if answer is correct
            if question.question_type in ('multiple_choice', 'true_false') and answer.selected_choice:
                answer.is_correct = answer.selected_choice.is_correct

            answer.save()

        # Complete the session
        session.status = 'completed'
        session.completed_at = timezone.now()
        session.save()

        # Calculate score
        final_score = calculate_quiz_score(session)

        # Build user_answers mapping for immediate client consumption
        user_answers = {}
        for answer in session.answers.select_related('question', 'selected_choice').all():
            user_answers[str(answer.question.id)] = {
                'selected_choice': answer.selected_choice.id if answer.selected_choice else None,
                'text_answer': answer.text_answer,
                'is_correct': answer.is_correct,
                'points_earned': answer.points_earned,
            }

        return Response({
            'message': 'Quiz submitted successfully',
            'score': final_score,
            'session_id': session.id,
            'user_answers': user_answers,
        }, status=status.HTTP_200_OK)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# Analytics Views

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def quiz_analytics(request, quiz_id):
    """Get analytics for a specific quiz"""
    quiz = get_object_or_404(Quiz, id=quiz_id)

    if quiz.created_by != request.user and request.user.user_type != 'admin':
        return Response({'error': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)

    sessions = QuizSession.objects.filter(quiz=quiz)
    completed_sessions = sessions.filter(status='completed')

    analytics = {
        'quiz_info': QuizSerializer(quiz).data,
        'total_participants': sessions.count(),
        'completed_participants': completed_sessions.count(),
        'completion_rate': (completed_sessions.count() / sessions.count() * 100) if sessions.count() > 0 else 0,
        'average_score': completed_sessions.aggregate(avg_score=Avg('score'))['avg_score'] or 0,
        'score_distribution': {
            'excellent': completed_sessions.filter(score__gte=90).count(),
            'good': completed_sessions.filter(score__gte=70, score__lt=90).count(),
            'average': completed_sessions.filter(score__gte=50, score__lt=70).count(),
            'poor': completed_sessions.filter(score__lt=50).count(),
        }
    }

    return Response(analytics)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def student_quiz_history(request):
    """Get quiz history for the current student"""
    if request.user.user_type != 'student':
        return Response({'error': 'Only students can view quiz history'},
                       status=status.HTTP_403_FORBIDDEN)

    sessions = QuizSession.objects.filter(student=request.user)

    paginator = StandardResultsSetPagination()
    page = paginator.paginate_queryset(sessions, request)
    if page is not None:
        serializer = QuizSessionSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)

    serializer = QuizSessionSerializer(sessions, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([])
def list_quiz_sessions(request):
    """List active quizzes that can be joined via quiz code."""
    # Prefer active LiveQuizSession entries (teacher-created live rooms).
    live_sessions = LiveQuizSession.objects.filter(is_active=True).order_by('-created_at')

    sessions_data = []
    for ls in live_sessions:
        sessions_data.append({
            'id': str(ls.id),
            'room_code': ls.room_code,
            'topic': ls.topic or ls.quiz.topic,
            'difficulty': ls.difficulty or ls.quiz.difficulty,
            'num_questions': ls.num_questions or ls.quiz.number_of_questions,
            'host': ls.host.username,
            'created_at': ls.created_at.isoformat(),
            'is_active': ls.is_active,
        })

    # If no live sessions exist, fall back to active quizzes so students still see joinable quizzes
    if not sessions_data:
        quizzes = Quiz.objects.filter(is_active=True).order_by('-created_at')
        for quiz in quizzes:
            sessions_data.append({
                'id': str(quiz.id),
                'room_code': quiz.quiz_code,
                'topic': quiz.topic,
                'difficulty': quiz.difficulty,
                'num_questions': quiz.number_of_questions,
                'host': quiz.created_by.username,
                'created_at': quiz.created_at.isoformat(),
                'is_active': quiz.is_active,
            })

    return Response(sessions_data)

@api_view(['GET'])
@permission_classes([])
def list_completed_quiz_sessions(request):
    """List inactive (completed/ended) live quiz sessions"""
    live_sessions = LiveQuizSession.objects.filter(is_active=False).order_by('-ended_at', '-created_at')

    sessions_data = []
    for session in live_sessions:
        sessions_data.append({
            'id': session.id,
            'room_code': session.room_code,
            'topic': session.topic,
            'difficulty': session.difficulty,
            'num_questions': session.num_questions,
            'host': session.host.username,
            'created_at': session.created_at.isoformat(),
            'ended_at': session.ended_at.isoformat() if session.ended_at else None,
            'is_active': session.is_active,
        })

    return Response(sessions_data)


# Live Kahoot-like endpoints

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def live_create(request):
    if request.user.user_type not in ['teacher', 'admin']:
        return Response({'error': 'Only teachers and admins can create live sessions'},
                        status=status.HTTP_403_FORBIDDEN)

    serializer = LiveSessionCreateSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    data = serializer.validated_data
    # Reuse AI generation to build a quiz and live session
    quiz = create_quiz_from_ai(
        title=f"Live: {data['topic']} ({data['difficulty']})",
        topic=data['topic'],
        difficulty=data['difficulty'],
        num_questions=data['number_of_questions'],
        created_by=request.user,
        time_limit=30,
    )

    # Create a LiveQuizSession so students can join the teacher-hosted game using the numeric room code.
    # Use the quiz.quiz_code as the room_code to keep things simple and visible to students.
    try:
        live = LiveQuizSession.objects.create(
            quiz=quiz,
            room_code=quiz.quiz_code,
            host=request.user,
            topic=quiz.topic,
            difficulty=quiz.difficulty,
            num_questions=quiz.number_of_questions,
            is_active=True,
            started_at=timezone.now(),
        )
    except Exception:
        # If creating a LiveQuizSession fails (e.g., room_code collision), fall back to returning the quiz code
        return Response({
            'room_code': quiz.quiz_code,
            'quiz_id': str(quiz.id),
        }, status=status.HTTP_201_CREATED)

    return Response({
        'room_code': live.room_code,
        'live_session_id': str(live.id),
        'quiz_id': str(quiz.id),
    }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def live_join(request):
    if request.user.user_type != 'student':
        return Response({'error': 'Only students can join live sessions'},
                        status=status.HTTP_403_FORBIDDEN)

    room_code = request.data.get('room_code')
    if not room_code:
        return Response({'error': 'room_code is required'}, status=status.HTTP_400_BAD_REQUEST)

    live_session = get_object_or_404(LiveQuizSession, room_code=room_code, is_active=True)
    LiveParticipant.objects.get_or_create(session=live_session, user=request.user)

    return Response({'message': 'Joined', 'room_code': room_code})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def live_state(request, room_code):
    live_session = get_object_or_404(LiveQuizSession, room_code=room_code, is_active=True)

    quiz = live_session.quiz
    current_index = live_session.current_question_index
    current_question = None
    if 0 <= current_index < quiz.questions.count():
        current_question = quiz.questions.order_by('order')[current_index]

    leaderboard = [
        {
            'username': p.user.username,
            'score': p.score,
        }
        for p in live_session.participants.order_by('-score')[:10]
    ]

    payload = {
        'room_code': live_session.room_code,
        'topic': live_session.topic,
        'difficulty': live_session.difficulty,
        'num_questions': live_session.num_questions,
        'current_question_index': current_index,
        'is_active': live_session.is_active,
        'leaderboard': leaderboard,
    }
    if current_question:
        payload['question'] = QuestionSerializer(current_question).data

    return Response(payload)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def live_answer(request, room_code):
    if request.user.user_type != 'student':
        return Response({'error': 'Only students can answer'}, status=status.HTTP_403_FORBIDDEN)

    live_session = get_object_or_404(LiveQuizSession, room_code=room_code, is_active=True)

    question_id = request.data.get('question_id')
    selected_choice_id = request.data.get('selected_choice_id')
    if not question_id or not selected_choice_id:
        return Response({'error': 'question_id and selected_choice_id are required'},
                        status=status.HTTP_400_BAD_REQUEST)

    question = get_object_or_404(Question, id=question_id, quiz=live_session.quiz)
    selected_choice = get_object_or_404(Choice, id=selected_choice_id, question=question)

    participant = get_object_or_404(LiveParticipant, session=live_session, user=request.user)
    if selected_choice.is_correct:
        participant.score += question.points
        participant.save()

    return Response({'correct': selected_choice.is_correct, 'score': participant.score})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def live_next(request, room_code):
    if request.user.user_type not in ['teacher', 'admin']:
        return Response({'error': 'Only host can control the quiz'}, status=status.HTTP_403_FORBIDDEN)

    live_session = get_object_or_404(LiveQuizSession, room_code=room_code, is_active=True, host=request.user)
    live_session.current_question_index += 1
    if live_session.current_question_index >= live_session.quiz.questions.count():
        live_session.is_active = False
        live_session.ended_at = timezone.now()
    live_session.save()

    return Response({'message': 'advanced', 'current_question_index': live_session.current_question_index, 'is_active': live_session.is_active})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def live_end(request, room_code):
    if request.user.user_type not in ['teacher', 'admin']:
        return Response({'error': 'Only host can end the quiz'}, status=status.HTTP_403_FORBIDDEN)

    live_session = get_object_or_404(LiveQuizSession, room_code=room_code, is_active=True, host=request.user)
    live_session.is_active = False
    live_session.ended_at = timezone.now()
    live_session.save()

    return Response({'message': 'ended'})