class Quiz {
  final String id;
  final String title;
  final String topic;
  final String difficulty;
  final int numberOfQuestions;
  final int timeLimit;
  final String createdBy;
  final bool isActive;
  final String quizCode;
  final DateTime createdAt;
  final List<Question> questions;

  Quiz({
    required this.id,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.numberOfQuestions,
    required this.timeLimit,
    required this.createdBy,
    required this.isActive,
    required this.quizCode,
    required this.createdAt,
    this.questions = const [],
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    // Defensive parsing: backend may return 'quiz_code' or 'room_code', and
    // some fields (created_by, number_of_questions) may be nested or missing.
    final id = (json['id'] ?? '').toString();
    final title = (json['title'] ?? '').toString();
    final topic = (json['topic'] ?? '').toString();
    final difficulty = (json['difficulty'] ?? 'mixed').toString();

    int parseInt(dynamic v, [int fallback = 0]) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    final numberOfQuestions = parseInt(json['number_of_questions'], 0);
    final timeLimit = parseInt(json['time_limit'], 0);

    String createdBy = '';
    final cb = json['created_by'];
    if (cb is String) {
      createdBy = cb;
    } else if (cb is Map && cb['username'] != null) {
      createdBy = cb['username'].toString();
    } else if (cb != null) {
      createdBy = cb.toString();
    }

    final isActive = (json['is_active'] is bool) ? json['is_active'] as bool : (json['is_active']?.toString() == 'True');

    // Accept either 'quiz_code' or 'room_code' returned by backend
    final quizCode = (json['quiz_code'] ?? json['room_code'] ?? '').toString();

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(json['created_at'].toString());
    } catch (_) {
      createdAt = DateTime.now();
    }

    final questionsJson = (json['questions'] as List<dynamic>?) ?? [];
    final questions = questionsJson.map((q) => Question.fromJson(q as Map<String, dynamic>)).toList();

    return Quiz(
      id: id,
      title: title,
      topic: topic,
      difficulty: difficulty,
      numberOfQuestions: numberOfQuestions,
      timeLimit: timeLimit,
      createdBy: createdBy,
      isActive: isActive,
      quizCode: quizCode,
      createdAt: createdAt,
      questions: questions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'topic': topic,
      'difficulty': difficulty,
      'number_of_questions': numberOfQuestions,
      'time_limit': timeLimit,
      'created_by': createdBy,
      'is_active': isActive,
      'quiz_code': quizCode,
      'created_at': createdAt.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}

class Question {
  final String id;
  final String questionText;
  final String questionType;
  final int points;
  final int order;
  final List<Choice> choices;

  Question({
    required this.id,
    required this.questionText,
    required this.questionType,
    required this.points,
    required this.order,
    this.choices = const [],
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'].toString(),
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String,
      points: json['points'] as int,
      order: json['order'] as int,
      choices: (json['choices'] as List<dynamic>?)
              ?.map((c) => Choice.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'question_type': questionType,
      'points': points,
      'order': order,
      'choices': choices.map((c) => c.toJson()).toList(),
    };
  }
}

class Choice {
  final String id;
  final String choiceText;
  final bool isCorrect;
  final int order;

  Choice({
    required this.id,
    required this.choiceText,
    required this.isCorrect,
    required this.order,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      id: json['id'].toString(),
      choiceText: json['choice_text'] as String,
      isCorrect: json['is_correct'] as bool? ?? false,
      order: json['order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'choice_text': choiceText,
      'is_correct': isCorrect,
      'order': order,
    };
  }
}

class QuizSession {
  final String id;
  final Quiz quiz;
  final String student;
  final String status;
  final double? score;
  final int? totalPoints;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, UserAnswer> userAnswers;

  QuizSession({
    required this.id,
    required this.quiz,
    required this.student,
    required this.status,
    this.score,
    this.totalPoints,
    required this.startedAt,
    this.completedAt,
    this.userAnswers = const {},
  });

  bool get isStarted => status == 'started';
  bool get isCompleted => status == 'completed';
  bool get isAbandoned => status == 'abandoned';

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    return QuizSession(
      id: json['id'] as String,
      quiz: Quiz.fromJson(json['quiz'] as Map<String, dynamic>),
      student: json['student'] as String,
      status: json['status'] as String,
      score: (json['score'] as num?)?.toDouble(),
      totalPoints: json['total_points'] as int?,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      userAnswers: (json['user_answers'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(
                    key,
                    UserAnswer.fromJson(value as Map<String, dynamic>),
                  )) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz': quiz.toJson(),
      'student': student,
      'status': status,
      'score': score,
      'total_points': totalPoints,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'user_answers': userAnswers.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}

class UserAnswer {
  final String? selectedChoiceId;
  final String? textAnswer;
  final bool isCorrect;
  final int pointsEarned;

  UserAnswer({
    this.selectedChoiceId,
    this.textAnswer,
    required this.isCorrect,
    required this.pointsEarned,
  });

  factory UserAnswer.fromJson(Map<String, dynamic> json) {
    return UserAnswer(
      selectedChoiceId: json['selected_choice']?.toString(),
      textAnswer: json['text_answer'] as String?,
      isCorrect: json['is_correct'] as bool,
      pointsEarned: json['points_earned'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selected_choice': selectedChoiceId,
      'text_answer': textAnswer,
      'is_correct': isCorrect,
      'points_earned': pointsEarned,
    };
  }
}

class QuizCreateRequest {
  final String title;
  final String topic;
  final String difficulty;
  final int numberOfQuestions;
  final int timeLimit;

  QuizCreateRequest({
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.numberOfQuestions,
    required this.timeLimit,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'topic': topic,
      'difficulty': difficulty,
      'number_of_questions': numberOfQuestions,
      'time_limit': timeLimit,
    };
  }
}