"""
Test script for PDF Analysis endpoints
Run Django server first: python lms_backend/manage.py runserver
"""
import requests
import json

BASE_URL = "http://localhost:8000"
API_BASE = f"{BASE_URL}/api"

def test_endpoints():
    """Test PDF Analysis endpoints"""
    print("PDF Analysis Module - Endpoint Test")
    print("=" * 60)
    
    # First, login to get token
    print("\n1. Testing Authentication...")
    login_data = {
        "username": "admin",
        "password": "admin123"
    }
    
    try:
        response = requests.post(f"{API_BASE}/auth/login/", json=login_data)
        if response.status_code == 200:
            token = response.json().get('token')
            print(f"✓ Login successful. Token: {token[:20]}...")
        else:
            print(f"✗ Login failed: {response.status_code}")
            print(f"  Response: {response.text}")
            print("\nPlease create an admin user first:")
            print("  cd lms_backend")
            print("  python manage.py createsuperuser")
            return
    except Exception as e:
        print(f"✗ Error connecting to server: {e}")
        print("\nMake sure Django server is running:")
        print("  cd lms_backend")
        print("  python manage.py runserver")
        return
    
    headers = {
        "Authorization": f"Token {token}"
    }
    
    # Test upload endpoint
    print("\n2. Testing PDF Upload Endpoint...")
    print(f"   POST {API_BASE}/pdf-analysis/upload")
    
    # Check if test PDF exists
    import os
    test_pdf = "test_document.pdf"
    if not os.path.exists(test_pdf):
        print(f"   ⚠ Test PDF not found: {test_pdf}")
        print("   Creating a simple test PDF...")
        # Create a simple test PDF
        try:
            from reportlab.pdfgen import canvas
            from reportlab.lib.pagesizes import letter
            
            c = canvas.Canvas(test_pdf, pagesize=letter)
            c.drawString(100, 750, "Test Document for PDF Analysis")
            c.drawString(100, 730, "This is a test document.")
            c.drawString(100, 710, "It contains some sample text for testing.")
            c.save()
            print(f"   ✓ Created test PDF: {test_pdf}")
        except ImportError:
            print("   ✗ reportlab not installed. Using existing PDF if available.")
    
    if os.path.exists(test_pdf):
        try:
            with open(test_pdf, 'rb') as f:
                files = {'file': (test_pdf, f, 'application/pdf')}
                metadata = {'title': 'Test Document', 'description': 'Testing PDF Analysis'}
                data = {'metadata': json.dumps(metadata)}
                
                response = requests.post(
                    f"{API_BASE}/pdf-analysis/upload",
                    headers=headers,
                    files=files,
                    data=data
                )
                
                if response.status_code == 201:
                    result = response.json()
                    file_id = result.get('file_id')
                    print(f"   ✓ Upload successful!")
                    print(f"     File ID: {file_id}")
                    print(f"     Status: {result.get('status')}")
                    
                    # Test analyze endpoint
                    print("\n3. Testing PDF Analysis Endpoint...")
                    print(f"   POST {API_BASE}/pdf-analysis/analyze")
                    
                    analyze_data = {
                        "file_id": file_id,
                        "task": "summarize",
                        "task_options": {
                            "summarize_length": "short"
                        },
                        "response_format": "text"
                    }
                    
                    response = requests.post(
                        f"{API_BASE}/pdf-analysis/analyze",
                        headers=headers,
                        json=analyze_data
                    )
                    
                    if response.status_code == 200:
                        result = response.json()
                        request_id = result.get('request_id')
                        print(f"   ✓ Analysis request created!")
                        print(f"     Request ID: {request_id}")
                        print(f"     Status: {result.get('status')}")
                        
                        # Test status endpoint
                        print("\n4. Testing Status Endpoint...")
                        print(f"   GET {API_BASE}/pdf-analysis/status/{request_id}")
                        
                        import time
                        time.sleep(2)  # Wait for processing
                        
                        response = requests.get(
                            f"{API_BASE}/pdf-analysis/status/{request_id}",
                            headers=headers
                        )
                        
                        if response.status_code == 200:
                            result = response.json()
                            print(f"   ✓ Status retrieved!")
                            print(f"     Status: {result.get('status')}")
                            if result.get('result'):
                                print(f"     Result type: {result['result'].get('type')}")
                                content = result['result'].get('content', '')
                                print(f"     Content preview: {content[:100]}...")
                        else:
                            print(f"   ✗ Status check failed: {response.status_code}")
                            print(f"     Response: {response.text}")
                    else:
                        print(f"   ✗ Analysis failed: {response.status_code}")
                        print(f"     Response: {response.text}")
                else:
                    print(f"   ✗ Upload failed: {response.status_code}")
                    print(f"     Response: {response.text}")
        except Exception as e:
            print(f"   ✗ Error: {e}")
    else:
        print(f"   ⚠ No test PDF available")
    
    print("\n" + "=" * 60)
    print("Test complete!")

if __name__ == '__main__':
    test_endpoints()
