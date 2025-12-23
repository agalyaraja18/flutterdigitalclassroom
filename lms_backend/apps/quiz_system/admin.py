from django.contrib import admin
from .models import Quiz, Question, Choice, QuizSession, Answer

class ChoiceInline(admin.TabularInline):
    model = Choice
    extra = 4

class QuestionInline(admin.TabularInline):
    model = Question
    extra = 1

@admin.register(Quiz)
class QuizAdmin(admin.ModelAdmin):
    list_display = ['title', 'topic', 'difficulty', 'number_of_questions', 'created_by', 'quiz_code', 'is_active', 'created_at']
    list_filter = ['difficulty', 'is_active', 'created_at', 'created_by__user_type']
    search_fields = ['title', 'topic', 'quiz_code', 'created_by__username']
    readonly_fields = ['quiz_code', 'created_at', 'updated_at']
    inlines = [QuestionInline]

    fieldsets = (
        ('Quiz Information', {
            'fields': ('title', 'topic', 'difficulty', 'number_of_questions', 'time_limit')
        }),
        ('Settings', {
            'fields': ('created_by', 'is_active', 'quiz_code')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
    list_display = ['quiz', 'question_text_short', 'question_type', 'points', 'order']
    list_filter = ['question_type', 'quiz__difficulty', 'quiz__topic']
    search_fields = ['question_text', 'quiz__title']
    inlines = [ChoiceInline]

    def question_text_short(self, obj):
        return obj.question_text[:50] + "..." if len(obj.question_text) > 50 else obj.question_text
    question_text_short.short_description = 'Question Text'

@admin.register(QuizSession)
class QuizSessionAdmin(admin.ModelAdmin):
    list_display = ['student', 'quiz', 'status', 'score', 'started_at', 'completed_at']
    list_filter = ['status', 'quiz__difficulty', 'started_at']
    search_fields = ['student__username', 'quiz__title']
    readonly_fields = ['started_at', 'completed_at']

@admin.register(Answer)
class AnswerAdmin(admin.ModelAdmin):
    list_display = ['session', 'question', 'selected_choice', 'is_correct', 'points_earned']
    list_filter = ['is_correct', 'question__question_type']
    search_fields = ['session__student__username', 'question__question_text']