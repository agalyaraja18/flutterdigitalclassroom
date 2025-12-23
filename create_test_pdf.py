from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
import requests
import os

def create_test_pdf():
    """Create a simple test PDF"""
    pdf_path = "test_document.pdf"

    # Create a simple PDF using reportlab
    doc = SimpleDocTemplate(pdf_path, pagesize=letter)
    styles = getSampleStyleSheet()
    story = []

    # Add content
    title = Paragraph("Sample PDF for LMS Testing", styles['Title'])
    story.append(title)
    story.append(Spacer(1, 12))

    content = """
    This is a test document for the PDF to Audio conversion feature.

    The LMS system can:
    • Upload PDF files
    • Extract text content automatically
    • Convert text to speech using AI
    • Provide downloadable audio files
    • Track conversion status in real-time

    Students can benefit from:
    - Listening while commuting
    - Audio learning for different learning styles
    - Accessibility features
    - Multitasking capabilities

    This completes our test document for the LMS system.
    """

    para = Paragraph(content, styles['Normal'])
    story.append(para)

    doc.build(story)
    print(f"Test PDF created: {pdf_path}")
    return pdf_path

def test_pdf_upload(pdf_path, auth_token):
    """Test PDF upload to the LMS API"""
    url = "http://localhost:8000/api/pdf/upload/"

    with open(pdf_path, 'rb') as f:
        files = {
            'pdf_file': (pdf_path, f, 'application/pdf')
        }
        data = {
            'title': 'Test Document for Audio Conversion'
        }
        headers = {
            'Authorization': f'Token {auth_token}'
        }

        print("Uploading PDF to LMS...")
        response = requests.post(url, files=files, data=data, headers=headers)

        if response.status_code == 201:
            result = response.json()
            print("PDF uploaded successfully!")
            print(f"Document ID: {result['id']}")
            print(f"Title: {result['title']}")
            print(f"Status: {result['conversion_status']}")
            return result['id']
        else:
            print(f"Upload failed: {response.status_code}")
            print(response.text)
            return None

def check_conversion_status(doc_id, auth_token):
    """Check PDF conversion status"""
    url = f"http://localhost:8000/api/pdf/documents/{doc_id}/"
    headers = {'Authorization': f'Token {auth_token}'}

    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        result = response.json()
        print(f"Conversion Status: {result['conversion_status']}")
        if result['audio_file']:
            print(f"Audio file ready: {result['audio_file']}")
        return result
    else:
        print(f"Failed to check status: {response.status_code}")
        return None

if __name__ == "__main__":
    try:
        # Try to import reportlab, if not available, skip PDF creation
        from reportlab.lib.pagesizes import letter
        pdf_path = create_test_pdf()
    except ImportError:
        print("reportlab not available, using text file instead")
        pdf_path = "test_document.txt"

    # Login to get auth token
    login_url = "http://localhost:8000/api/auth/login/"
    login_data = {"username": "admin", "password": "admin123"}

    print("Logging in...")
    response = requests.post(login_url, json=login_data)

    if response.status_code == 200:
        auth_token = response.json()['token']
        print("Login successful!")

        # Test PDF upload only if we have a PDF
        if pdf_path.endswith('.pdf'):
            doc_id = test_pdf_upload(pdf_path, auth_token)

            if doc_id:
                print("\nWaiting for conversion...")
                import time
                for i in range(10):
                    time.sleep(3)
                    result = check_conversion_status(doc_id, auth_token)
                    if result and result['conversion_status'] == 'completed':
                        print("Audio conversion completed!")
                        break
                    elif result and result['conversion_status'] == 'failed':
                        print("Audio conversion failed!")
                        break
                    print(f"Still processing... ({i+1}/10)")
        else:
            print("No PDF file available for testing")

    else:
        print(f"Login failed: {response.status_code}")
        print(response.text)