import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_backend.settings')
django.setup()

from apps.authentication.models import User

try:
    admin_user = User.objects.get(username='admin')
    admin_user.set_password('admin123')
    admin_user.user_type = 'admin'
    admin_user.save()
    print("Admin password set successfully!")
except User.DoesNotExist:
    print("Admin user not found")