"""
Test script to debug PDF text extraction
Run this to test if your PDF can be read properly
"""
import sys
import os

# Add Django project to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lms_backend'))

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_backend.settings')
import django
django.setup()

from apps.pdf_converter.models import PDFDocument
from apps.pdf_converter.utils import extract_text_from_pdf

def test_latest_pdf():
    """Test the most recently uploaded PDF"""
    print("=" * 60)
    print("PDF Text Extraction Test")
    print("=" * 60)
    
    # Get the latest PDF document
    try:
        latest_doc = PDFDocument.objects.latest('created_at')
        print(f"\nTesting PDF: {latest_doc.title}")
        print(f"File: {latest_doc.pdf_file.name}")
        print(f"Status: {latest_doc.conversion_status}")
        print(f"Uploaded by: {latest_doc.uploaded_by.username}")
        print("-" * 60)
        
        # Try to extract text
        print("\nAttempting text extraction...")
        with latest_doc.pdf_file.open('rb') as pdf_file:
            text = extract_text_from_pdf(pdf_file)
        
        print("\n" + "=" * 60)
        print("EXTRACTION RESULT:")
        print("=" * 60)
        print(f"Text length: {len(text)} characters")
        print(f"\nFirst 500 characters:")
        print("-" * 60)
        print(text[:500])
        print("-" * 60)
        
        if "No text content could be extracted" in text:
            print("\n⚠️  WARNING: Text extraction failed!")
            print("This PDF may be:")
            print("  - A scanned image (needs OCR)")
            print("  - Protected/encrypted")
            print("  - Using unsupported fonts/encoding")
        else:
            print("\n✓ Text extraction successful!")
            
        # Check what's stored in the database
        print("\n" + "=" * 60)
        print("DATABASE STORED TEXT:")
        print("=" * 60)
        if latest_doc.text_content:
            print(f"Length: {len(latest_doc.text_content)} characters")
            print(f"First 200 characters: {latest_doc.text_content[:200]}")
        else:
            print("No text content stored in database yet")
            
    except PDFDocument.DoesNotExist:
        print("No PDF documents found in database")
        print("Please upload a PDF first through the app")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    test_latest_pdf()
