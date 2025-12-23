import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_backend.settings')
django.setup()

from apps.authentication.models import User

# Create demo users
demo_users = [
    {
        'username': 'teacher',
        'email': 'teacher@example.com',
        'first_name': 'Teacher',
        'last_name': 'Demo',
        'user_type': 'teacher',
        'password': 'teacher123'
    },
    {
        'username': 'student',
        'email': 'student@example.com',
        'first_name': 'Student',
        'last_name': 'Demo',
        'user_type': 'student',
        'password': 'student123'
    }
]

for user_data in demo_users:
    password = user_data.pop('password')
    user, created = User.objects.get_or_create(
        username=user_data['username'],
        defaults=user_data
    )
    if created:
        user.set_password(password)
        user.save()
        print(f"Created user: {user.username} ({user.user_type})")
    else:
        print(f"User already exists: {user.username}")

print("Demo users created successfully!")