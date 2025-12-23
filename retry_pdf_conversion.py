import os
import sys
import django

# Add the Django project to the Python path
sys.path.append('D:/abishek/Flutterproject/lms_backend')

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_backend.settings')
django.setup()

from apps.pdf_converter.models import PDFDocument
from apps.pdf_converter.utils import process_pdf_to_audio

def retry_failed_conversions():
    """Retry all failed PDF conversions"""
    failed_docs = PDFDocument.objects.filter(conversion_status='failed')

    print(f"Found {failed_docs.count()} failed conversions to retry")

    for doc in failed_docs:
        print(f"\nRetrying conversion for: {doc.title}")
        try:
            success = process_pdf_to_audio(doc)
            if success:
                print(f"[SUCCESS] Successfully converted: {doc.title}")
            else:
                print(f"[FAILED] Conversion still failed: {doc.title}")
        except Exception as e:
            print(f"[ERROR] Error retrying {doc.title}: {e}")

if __name__ == "__main__":
    retry_failed_conversions()