from django.db import models
from django.contrib.auth import get_user_model
import uuid
import random
import string

User = get_user_model()

class Quiz(models.Model):
    DIFFICULTY_CHOICES = [
        ('easy', 'Easy'),
        ('medium', 'Medium'),
        ('hard', 'Hard'),
        ('mixed', 'Mixed'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255)
    topic = models.CharField(max_length=255)
    difficulty = models.CharField(max_length=10, choices=DIFFICULTY_CHOICES)
    number_of_questions = models.IntegerField()
    time_limit = models.IntegerField(help_text="Time limit in minutes", default=30)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_quizzes')
    is_active = models.BooleanField(default=True)
    quiz_code = models.CharField(max_length=8, unique=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        """Generate quiz_code if not set"""
        if not self.quiz_code:
            self.quiz_code = self.generate_quiz_code()
        super().save(*args, **kwargs)
    
    def generate_quiz_code(self):
        """Generate a unique 6-digit numeric quiz code"""
        while True:
            code = ''.join(random.choices(string.digits, k=6))
            if not Quiz.objects.filter(quiz_code=code).exists():
                return code

    def __str__(self):
        return f"{self.title} - {self.topic}"

    class Meta:
        ordering = ['-created_at']

class Question(models.Model):
    QUESTION_TYPES = [
        ('multiple_choice', 'Multiple Choice'),
        ('true_false', 'True/False'),
        ('short_answer', 'Short Answer'),
    ]

    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name='questions')
    question_text = models.TextField()
    question_type = models.CharField(max_length=20, choices=QUESTION_TYPES, default='multiple_choice')
    points = models.IntegerField(default=1)
    order = models.IntegerField()

    def __str__(self):
        return f"Q{self.order}: {self.question_text[:50]}..."

    class Meta:
        ordering = ['order']

class Choice(models.Model):
    question = models.ForeignKey(Question, on_delete=models.CASCADE, related_name='choices')
    choice_text = models.CharField(max_length=255)
    is_correct = models.BooleanField(default=False)
    order = models.IntegerField()

    def __str__(self):
        return f"{self.choice_text} ({'Correct' if self.is_correct else 'Incorrect'})"

    class Meta:
        ordering = ['order']

class QuizSession(models.Model):
    STATUS_CHOICES = [
        ('started', 'Started'),
        ('completed', 'Completed'),
        ('abandoned', 'Abandoned'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name='sessions')
    student = models.ForeignKey(User, on_delete=models.CASCADE, related_name='quiz_sessions')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='started')
    score = models.FloatField(null=True, blank=True)
    total_points = models.IntegerField(null=True, blank=True)
    started_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.student.username} - {self.quiz.title}"

    class Meta:
        ordering = ['-started_at']

class Answer(models.Model):
    session = models.ForeignKey(QuizSession, on_delete=models.CASCADE, related_name='answers')
    question = models.ForeignKey(Question, on_delete=models.CASCADE)
    selected_choice = models.ForeignKey(Choice, on_delete=models.CASCADE, null=True, blank=True)
    text_answer = models.TextField(null=True, blank=True)
    is_correct = models.BooleanField(default=False)
    points_earned = models.IntegerField(default=0)

    def __str__(self):
        return f"{self.session.student.username} - Q{self.question.order}"

    class Meta:
        unique_together = ['session', 'question']

class LiveQuizSession(models.Model):
    """Live quiz session that teachers create and students join with room codes"""
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name='live_sessions')
    room_code = models.CharField(max_length=6, unique=True)
    host = models.ForeignKey(User, on_delete=models.CASCADE, related_name='hosted_quiz_sessions')
    topic = models.CharField(max_length=255)
    difficulty = models.CharField(max_length=10, default='mixed')
    num_questions = models.IntegerField(default=10)
    is_active = models.BooleanField(default=True)
    current_question_index = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    started_at = models.DateTimeField(null=True, blank=True)
    ended_at = models.DateTimeField(null=True, blank=True)

    def save(self, *args, **kwargs):
        if not self.room_code:
            self.room_code = self.generate_room_code()
        super().save(*args, **kwargs)

    def generate_room_code(self):
        """Generate a unique 6-digit room code"""
        while True:
            code = ''.join(random.choices(string.digits, k=6))
            if not LiveQuizSession.objects.filter(room_code=code, is_active=True).exists():
                return code

    def __str__(self):
        return f"{self.topic} - {self.room_code}"

    class Meta:
        ordering = ['-created_at']


class LiveParticipant(models.Model):
    """Participants in a live session, tracking simple score for leaderboard"""
    session = models.ForeignKey(LiveQuizSession, on_delete=models.CASCADE, related_name='participants')
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    score = models.IntegerField(default=0)
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('session', 'user')