"""
Test script for PDF Analysis module
"""
import os
import sys
import django

# Add the lms_backend directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lms_backend'))

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_backend.settings')
django.setup()

from apps.pdf_analyzer.analysis_service import get_analysis_service

def test_api_key():
    """Test if API key is configured correctly"""
    print("Testing PDF Analysis Service...")
    print("-" * 50)
    
    # Check environment variable
    api_key = os.getenv('AI_API_KEY')
    if api_key:
        print(f"✓ AI_API_KEY found in environment: {api_key[:10]}...")
    else:
        print("✗ AI_API_KEY not found in environment")
    
    # Try to initialize service
    try:
        service = get_analysis_service()
        if service:
            print(f"✓ PDF Analysis Service initialized successfully")
            print(f"  Model: {service.model_name}")
            print(f"  Max tokens: {service.max_tokens}")
            print(f"  Temperature: {service.temperature}")
        else:
            print("✗ PDF Analysis Service failed to initialize")
    except Exception as e:
        print(f"✗ Error initializing service: {e}")
    
    print("-" * 50)

if __name__ == '__main__':
    test_api_key()
