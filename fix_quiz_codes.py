"""
Script to check and fix quiz codes for existing quizzes
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

def fix_quiz_codes():
    """Check and fix quiz codes for all quizzes"""
    print("=" * 60)
    print("Quiz Code Checker and Fixer")
    print("=" * 60)
    
    # Get all quizzes
    all_quizzes = Quiz.objects.all()
    print(f"\nTotal quizzes in database: {all_quizzes.count()}")
    
    # Find quizzes without codes
    quizzes_without_codes = Quiz.objects.filter(quiz_code='')
    quizzes_with_codes = Quiz.objects.exclude(quiz_code='')
    
    print(f"Quizzes with codes: {quizzes_with_codes.count()}")
    print(f"Quizzes without codes: {quizzes_without_codes.count()}")
    
    if quizzes_with_codes.exists():
        print("\n" + "-" * 60)
        print("Quizzes with codes:")
        print("-" * 60)
        for quiz in quizzes_with_codes:
            print(f"  ✓ {quiz.title[:40]:40} | Code: {quiz.quiz_code}")
    
    if quizzes_without_codes.exists():
        print("\n" + "-" * 60)
        print("Fixing quizzes without codes...")
        print("-" * 60)
        for quiz in quizzes_without_codes:
            old_code = quiz.quiz_code
            quiz.save()  # This will trigger the save() method and generate a code
            print(f"  ✓ {quiz.title[:40]:40} | Generated: {quiz.quiz_code}")
        
        print(f"\n✓ Fixed {quizzes_without_codes.count()} quizzes!")
    else:
        print("\n✓ All quizzes already have codes!")
    
    # Verify all quizzes now have codes
    print("\n" + "=" * 60)
    print("Final Verification:")
    print("=" * 60)
    remaining_without_codes = Quiz.objects.filter(quiz_code='')
    if remaining_without_codes.exists():
        print(f"⚠️  WARNING: {remaining_without_codes.count()} quizzes still don't have codes!")
        for quiz in remaining_without_codes:
            print(f"  - {quiz.title} (ID: {quiz.id})")
    else:
        print("✓ All quizzes now have valid codes!")
        print(f"\nTotal quizzes: {Quiz.objects.count()}")
        print(f"All have codes: {Quiz.objects.exclude(quiz_code='').count()}")

if __name__ == '__main__':
    fix_quiz_codes()
