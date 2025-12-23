try:
    import google.generativeai as genai  # type: ignore
except Exception:  # ImportError or any env-related error
    genai = None
import json
import os
import random
import string
from django.conf import settings
from .models import Quiz, Question, Choice, LiveQuizSession

def generate_quiz_code():
    """Generate a unique 6-digit numeric quiz code"""
    # Generate a numeric 6-digit code to make it easy for students to type
    while True:
        code = ''.join(random.choices(string.digits, k=6))
        if not Quiz.objects.filter(quiz_code=code).exists():
            return code

def generate_sample_questions(topic, difficulty, num_questions):
    """Generate sample questions when OpenAI API is not available"""
    sample_questions_templates = {
        'science': [
            {
                "question": "What is the chemical symbol for water?",
                "options": ["H2O", "CO2", "NaCl", "O2"],
                "correct_answer": 0,
                "explanation": "Water is composed of two hydrogen atoms and one oxygen atom, hence H2O."
            },
            {
                "question": "Which planet is closest to the Sun?",
                "options": ["Venus", "Mercury", "Mars", "Earth"],
                "correct_answer": 1,
                "explanation": "Mercury is the innermost planet in our solar system."
            },
            {
                "question": "What is the powerhouse of the cell?",
                "options": ["Nucleus", "Ribosome", "Mitochondria", "Cell membrane"],
                "correct_answer": 2,
                "explanation": "Mitochondria produce energy (ATP) for cellular processes."
            }
        ],
        'math': [
            {
                "question": "What is 2 + 2?",
                "options": ["3", "4", "5", "6"],
                "correct_answer": 1,
                "explanation": "Basic addition: 2 + 2 = 4"
            },
            {
                "question": "What is the square root of 16?",
                "options": ["2", "4", "6", "8"],
                "correct_answer": 1,
                "explanation": "4 × 4 = 16, so √16 = 4"
            },
            {
                "question": "What is 10% of 100?",
                "options": ["5", "10", "15", "20"],
                "correct_answer": 1,
                "explanation": "10% of 100 = 0.10 × 100 = 10"
            }
        ],
        'history': [
            {
                "question": "Who was the first President of the United States?",
                "options": ["Thomas Jefferson", "George Washington", "John Adams", "Benjamin Franklin"],
                "correct_answer": 1,
                "explanation": "George Washington served as the first President from 1789 to 1797."
            },
            {
                "question": "In which year did World War II end?",
                "options": ["1944", "1945", "1946", "1947"],
                "correct_answer": 1,
                "explanation": "World War II ended in 1945 with the surrender of Japan."
            }
        ],
        'geography': [
            {
                "question": "Which is the largest ocean on Earth?",
                "options": ["Atlantic Ocean", "Indian Ocean", "Pacific Ocean", "Arctic Ocean"],
                "correct_answer": 2,
                "explanation": "The Pacific Ocean is the largest and deepest ocean on Earth."
            },
            {
                "question": "Mount Everest lies on the border of which two countries?",
                "options": ["India and China", "Nepal and China", "Bhutan and India", "Nepal and India"],
                "correct_answer": 1,
                "explanation": "Everest sits on the border between Nepal and China (Tibet)."
            }
        ],
        'english': [
            {
                "question": "Choose the correct synonym for 'rapid'",
                "options": ["slow", "swift", "dull", "late"],
                "correct_answer": 1,
                "explanation": "'Swift' is a synonym for 'rapid'."
            },
            {
                "question": "Identify the figure of speech: 'The wind whispered through the trees.'",
                "options": ["Metaphor", "Simile", "Personification", "Hyperbole"],
                "correct_answer": 2,
                "explanation": "Attributing human action to wind is personification."
            }
        ],
        'computer_science': [
            {
                "question": "What does CPU stand for?",
                "options": ["Central Processing Unit", "Computer Personal Unit", "Central Program Utility", "Core Processing Utility"],
                "correct_answer": 0,
                "explanation": "CPU is Central Processing Unit."
            },
            {
                "question": "Which data structure uses FIFO order?",
                "options": ["Stack", "Queue", "Tree", "Graph"],
                "correct_answer": 1,
                "explanation": "Queue follows First-In-First-Out order."
            }
        ],
    }

    # Default questions for any topic
    default_questions = [
        {
            "question": f"This is a sample question about {topic}. What is the correct answer?",
            "options": ["Option A", "Option B (Correct)", "Option C", "Option D"],
            "correct_answer": 1,
            "explanation": f"This is a sample explanation for {topic}."
        },
        {
            "question": f"Another sample question about {topic}. Which is correct?",
            "options": ["Wrong answer", "Wrong answer", "Correct answer", "Wrong answer"],
            "correct_answer": 2,
            "explanation": f"This explains the correct answer for {topic}."
        }
    ]

    # Choose questions based on topic
    topic_lower = topic.lower()
    if 'science' in topic_lower or 'physics' in topic_lower or 'chemistry' in topic_lower or 'biology' in topic_lower:
        questions = sample_questions_templates['science']
    elif 'math' in topic_lower or 'mathematics' in topic_lower:
        questions = sample_questions_templates['math']
    elif 'history' in topic_lower:
        questions = sample_questions_templates['history']
    elif 'geography' in topic_lower:
        questions = sample_questions_templates['geography']
    elif 'english' in topic_lower or 'grammar' in topic_lower or 'literature' in topic_lower:
        questions = sample_questions_templates['english']
    elif 'computer' in topic_lower or 'programming' in topic_lower or 'cs' in topic_lower or 'software' in topic_lower:
        questions = sample_questions_templates['computer_science']
    else:
        questions = default_questions

    # Generate more questions with real variations
    result = []
    base_questions = questions.copy()
    question_patterns = [
        lambda q: {**q, "question": f"Consider this: {q['question']}"},
        lambda q: {**q, "question": f"Analyze the following: {q['question']}"},
        lambda q: {**q, "question": q['question'].replace('What', 'Which').replace('?', '?\nSelect the best answer:')},
        lambda q: {**q, "question": f"From the given options, {q['question'].lower()}"},
    ]
    
    used_questions = set()  # Track used question texts
    
    while len(result) < num_questions:
        if not base_questions:
            # Create meaningful variations using patterns
            new_variations = []
            for q in questions:
                for pattern in question_patterns:
                    new_q = pattern(q.copy())
                    if new_q['question'] not in used_questions:
                        # Shuffle options while keeping track of correct answer
                        correct_option = new_q['options'][new_q['correct_answer']]
                        random.shuffle(new_q['options'])
                        new_q['correct_answer'] = new_q['options'].index(correct_option)
                        new_variations.append(new_q)
            
            # If still need more, create additional variations with modified options
            if not new_variations:
                for q in questions:
                    new_q = q.copy()
                    new_q['question'] = f"Final review: {q['question']}"
                    # Modify some option wordings while preserving meaning
                    new_q['options'] = [f"{opt} (Select this)" if i == new_q['correct_answer'] 
                                       else f"Not {opt}" for i, opt in enumerate(new_q['options'])]
                    new_variations.append(new_q)
            
            base_questions.extend(new_variations)
            if not base_questions:  # If still empty, we've exhausted all variations
                break
        
        # Randomly select and remove a question
        question = random.choice(base_questions)
        base_questions.remove(question)
        used_questions.add(question['question'])
        result.append(question)
    
    # If we still don't have enough questions, pad with clearly marked duplicates
    while len(result) < num_questions:
        q = random.choice(questions).copy()
        q['question'] = f"Review Question #{len(result) + 1}: {q['question']}"
        result.append(q)

    # Final dedupe: ensure question texts are unique (preserve order)
    seen = set()
    deduped = []
    for q in result:
        qt = q.get('question')
        if qt is None:
            continue
        if qt in seen:
            continue
        seen.add(qt)
        deduped.append(q)

    # If deduping removed items and we have fewer questions, pad with simple variants
    i = 0
    while len(deduped) < num_questions:
        base = questions[i % len(questions)].copy()
        base['question'] = f"Extra: {base['question']} ({len(deduped) + 1})"
        deduped.append(base)
        i += 1

    return deduped

def generate_questions_with_ai(topic, difficulty, num_questions):
    """Generate quiz questions using Gemini API with fallback"""
    # Prefer explicit environment variable, fall back to Django settings if available
    api_key = os.getenv('GEMINI_API_KEY') or getattr(settings, 'GEMINI_API_KEY', None)
    if not api_key or genai is None:
        print("Gemini API key not configured or Gemini SDK unavailable, using sample questions")
        return generate_sample_questions(topic, difficulty, num_questions)

    try:
        # Configure Gemini API
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-2.5-flash')

        # Prepare the prompt based on difficulty
        difficulty_instructions = {
            'easy': 'Generate easy level questions suitable for beginners',
            'medium': 'Generate medium level questions with moderate complexity',
            'hard': 'Generate hard level questions that are challenging and require deep understanding',
            'mixed': 'Generate a mix of easy, medium, and hard level questions'
        }

        prompt = f"""
        Generate {num_questions} multiple choice questions about {topic}.
        {difficulty_instructions[difficulty]}.

        Requirements:
        - Each question should have 4 options (A, B, C, D)
        - Clearly indicate the correct answer
        - Questions should be educational and relevant to the topic
        - Avoid ambiguous or trick questions
        - Provide varied question types within the topic

        Format your response as a JSON array with this structure:
        [
            {{
                "question": "Question text here?",
                "options": [
                    "Option A text",
                    "Option B text",
                    "Option C text",
                    "Option D text"
                ],
                "correct_answer": 0,
                "explanation": "Brief explanation of why this is correct"
            }}
        ]

        Where correct_answer is the index (0-3) of the correct option.
        Return ONLY the JSON array, no additional text.
        """

        response = model.generate_content(prompt)
        content = response.text

        # Try to extract JSON from the response
        try:
            # Find JSON array in the response
            start_idx = content.find('[')
            end_idx = content.rfind(']') + 1
            if start_idx != -1 and end_idx != 0:
                json_str = content[start_idx:end_idx]
                questions_data = json.loads(json_str)
            else:
                questions_data = json.loads(content)
        except json.JSONDecodeError:
            # Fallback: try to parse the entire content
            questions_data = json.loads(content)

        # Normalize the questions list to match num_questions and ensure structure
        if not isinstance(questions_data, list):
            raise ValueError('AI did not return a list')

        # Filter/transform any malformed items
        normalized = []
        for item in questions_data:
            if not isinstance(item, dict):
                continue
            qtext = item.get('question')
            options = item.get('options')
            correct = item.get('correct_answer', 0)
            if not isinstance(qtext, str) or not isinstance(options, list) or len(options) < 2:
                continue
            try:
                correct_idx = int(correct)
            except (TypeError, ValueError):
                correct_idx = 0
            if correct_idx < 0 or correct_idx >= len(options):
                correct_idx = 0
            normalized.append({
                'question': qtext,
                'options': options[:4] if len(options) >= 4 else (options + ["Option C", "Option D"])[:4],
                'correct_answer': correct_idx,
                'explanation': item.get('explanation', f'About {topic}')
            })

        # If AI returned fewer than needed, pad with samples; if more, trim
        if len(normalized) < num_questions:
            filler = generate_sample_questions(topic, difficulty, num_questions - len(normalized))
            normalized.extend(filler)
        elif len(normalized) > num_questions:
            normalized = normalized[:num_questions]

        # Dedupe by question text to avoid exact repeats
        seen_q = set()
        unique = []
        for it in normalized:
            qt = it.get('question')
            if qt and qt not in seen_q:
                seen_q.add(qt)
                unique.append(it)

        # If dedupe removed items, pad with sample questions
        if len(unique) < num_questions:
            filler = generate_sample_questions(topic, difficulty, num_questions - len(unique))
            unique.extend(filler)

        return unique[:num_questions]

    except Exception as e:
        print(f"Gemini API failed: {str(e)}, using sample questions")
        return generate_sample_questions(topic, difficulty, num_questions)

def create_quiz_from_ai(title, topic, difficulty, num_questions, created_by, time_limit=30):
    """Create a complete quiz using AI-generated questions"""
    try:
        # Generate questions using AI
        questions_data = generate_questions_with_ai(topic, difficulty, num_questions)

        # Create the quiz
        quiz = Quiz.objects.create(
            title=title,
            topic=topic,
            difficulty=difficulty,
            number_of_questions=num_questions,
            time_limit=time_limit,
            created_by=created_by,
            quiz_code=generate_quiz_code(),
            is_active=True
        )

        # Create questions and choices
        for i, q_data in enumerate(questions_data):
            question = Question.objects.create(
                quiz=quiz,
                question_text=q_data['question'],
                question_type='multiple_choice',
                points=1,
                order=i + 1
            )

            # Determine correct index safely
            try:
                correct_idx = int(q_data.get('correct_answer', 0))
            except (TypeError, ValueError):
                correct_idx = 0
            options = list(q_data.get('options', []))
            if not options:
                # Fallback: generate placeholder options if missing
                options = ["Option A", "Option B", "Option C", "Option D"]
            if correct_idx < 0 or correct_idx >= len(options):
                correct_idx = 0

            # Create choices and ensure exactly one correct
            created_choices = []
            for j, choice_text in enumerate(options):
                created_choices.append(
                    Choice.objects.create(
                        question=question,
                        choice_text=choice_text,
                        is_correct=(j == correct_idx),
                        order=j + 1
                    )
                )

            # Safety net: ensure at least one correct choice
            if not any(c.is_correct for c in created_choices):
                first_choice = created_choices[0]
                first_choice.is_correct = True
                first_choice.save(update_fields=["is_correct"]) 

        # Previously we created a LiveQuizSession here for teacher-controlled live quizzes.
        # For the simplified flow we now return the created Quiz and use the quiz's
        # `quiz_code` as the room code students can use to join. Do NOT create
        # a LiveQuizSession automatically — that enables students to join by code
        # and take the quiz independently (Next/Submit is client-driven).

        return quiz

    except Exception as e:
        raise Exception(f"Error creating quiz: {str(e)}")

def calculate_quiz_score(session):
    """Calculate the final score for a quiz session"""
    answers = session.answers.all()
    total_points = 0
    earned_points = 0

    for answer in answers:
        total_points += answer.question.points
        if answer.is_correct:
            earned_points += answer.question.points
            answer.points_earned = answer.question.points
        else:
            answer.points_earned = 0
        answer.save()

    score_percentage = (earned_points / total_points * 100) if total_points > 0 else 0

    session.score = round(score_percentage, 2)
    session.total_points = total_points
    session.save()

    return session.score