"""
Test script to verify quiz API returns quiz_code
"""
import sys
import os

# Add Django project to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lms_backend'))

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_backend.settings')
import django
django.setup()

from apps.quiz_system.models import Quiz
from apps.quiz_system.serializers import QuizSerializer

def test_quiz_serializer():
    """Test if QuizSerializer includes quiz_code"""
    print("=" * 60)
    print("Quiz API Serializer Test")
    print("=" * 60)
    
    # Get the latest quiz
    latest_quiz = Quiz.objects.latest('created_at')
    
    print(f"\nLatest Quiz:")
    print(f"  Title: {latest_quiz.title}")
    print(f"  Topic: {latest_quiz.topic}")
    print(f"  Quiz Code (from model): {latest_quiz.quiz_code}")
    print(f"  Is Active: {latest_quiz.is_active}")
    
    # Serialize it
    serializer = QuizSerializer(latest_quiz)
    data = serializer.data
    
    print("\n" + "-" * 60)
    print("Serialized Data (what API returns):")
    print("-" * 60)
    import json
    print(json.dumps(data, indent=2, default=str))
    
    print("\n" + "=" * 60)
    print("Verification:")
    print("=" * 60)
    
    if 'quiz_code' in data:
        if data['quiz_code']:
            print(f"✓ quiz_code is present: {data['quiz_code']}")
        else:
            print(f"⚠️  quiz_code is present but EMPTY!")
    else:
        print("✗ quiz_code is NOT in serialized data!")
    
    # Also check room_code (for compatibility)
    if 'room_code' in data:
        print(f"✓ room_code is also present: {data['room_code']}")
    else:
        print("  (room_code not in response - this is OK, quiz_code is used)")

if __name__ == '__main__':
    test_quiz_serializer()
