from rest_framework import serializers
from .models import Quiz, Question, Choice, QuizSession, Answer, LiveQuizSession, LiveParticipant

class ChoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Choice
        fields = ['id', 'choice_text', 'order']

class ChoiceWithAnswerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Choice
        fields = ['id', 'choice_text', 'is_correct', 'order']

class QuestionSerializer(serializers.ModelSerializer):
    choices = ChoiceSerializer(many=True, read_only=True)

    class Meta:
        model = Question
        fields = ['id', 'question_text', 'question_type', 'points', 'order', 'choices']

class QuestionWithAnswersSerializer(serializers.ModelSerializer):
    choices = ChoiceWithAnswerSerializer(many=True, read_only=True)

    class Meta:
        model = Question
        fields = ['id', 'question_text', 'question_type', 'points', 'order', 'choices']

class QuizSerializer(serializers.ModelSerializer):
    created_by = serializers.StringRelatedField(read_only=True)

    class Meta:
        model = Quiz
        fields = ['id', 'title', 'topic', 'difficulty', 'number_of_questions', 'time_limit',
                 'created_by', 'is_active', 'quiz_code', 'created_at']

class QuizDetailSerializer(serializers.ModelSerializer):
    questions = QuestionSerializer(many=True, read_only=True)
    created_by = serializers.StringRelatedField(read_only=True)

    class Meta:
        model = Quiz
        fields = ['id', 'title', 'topic', 'difficulty', 'number_of_questions', 'time_limit',
                 'created_by', 'is_active', 'quiz_code', 'created_at', 'questions']

class QuizResultSerializer(serializers.ModelSerializer):
    questions = QuestionWithAnswersSerializer(many=True, read_only=True)
    created_by = serializers.StringRelatedField(read_only=True)

    class Meta:
        model = Quiz
        fields = ['id', 'title', 'topic', 'difficulty', 'number_of_questions', 'time_limit',
                 'created_by', 'quiz_code', 'questions']

class QuizCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Quiz
        fields = ['title', 'topic', 'difficulty', 'number_of_questions', 'time_limit']

    def validate_number_of_questions(self, value):
        if value < 1 or value > 50:
            raise serializers.ValidationError("Number of questions must be between 1 and 50")
        return value

    def validate_time_limit(self, value):
        if value < 1 or value > 300:  # Max 5 hours
            raise serializers.ValidationError("Time limit must be between 1 and 300 minutes")
        return value

class QuizSessionSerializer(serializers.ModelSerializer):
    quiz = QuizSerializer(read_only=True)
    student = serializers.StringRelatedField(read_only=True)

    class Meta:
        model = QuizSession
        fields = ['id', 'quiz', 'student', 'status', 'score', 'total_points', 'started_at', 'completed_at']

class AnswerSerializer(serializers.ModelSerializer):
    # Accept question as integer primary key (matches Question model default PK)
    question = serializers.IntegerField()
    selected_choice = serializers.IntegerField(required=False, allow_null=True)

    class Meta:
        model = Answer
        fields = ['question', 'selected_choice', 'text_answer']

class AnswerSubmissionSerializer(serializers.Serializer):
    answers = AnswerSerializer(many=True)

    def validate_answers(self, value):
        if not value:
            raise serializers.ValidationError("At least one answer is required")
        return value

class QuizJoinSerializer(serializers.Serializer):
    quiz_code = serializers.CharField(max_length=8)

    def validate_quiz_code(self, value):
        # Check if it's a regular quiz code
        try:
            quiz = Quiz.objects.get(quiz_code=value.upper(), is_active=True)
            return value.upper()
        except Quiz.DoesNotExist:
            pass

        # Check if it's a live session room code
        try:
            live_session = LiveQuizSession.objects.get(room_code=value, is_active=True)
            return value
        except LiveQuizSession.DoesNotExist:
            raise serializers.ValidationError("Invalid or inactive quiz code")

        return value


class LiveSessionCreateSerializer(serializers.Serializer):
    topic = serializers.CharField(max_length=255)
    difficulty = serializers.ChoiceField(choices=['easy', 'medium', 'hard', 'mixed'])
    number_of_questions = serializers.IntegerField(min_value=1, max_value=50)


class LiveSessionStateSerializer(serializers.Serializer):
    room_code = serializers.CharField()
    topic = serializers.CharField()
    difficulty = serializers.CharField()
    num_questions = serializers.IntegerField()
    current_question_index = serializers.IntegerField()
    is_active = serializers.BooleanField()
    question = QuestionSerializer(required=False)
    leaderboard = serializers.ListField(child=serializers.DictField(), required=False)