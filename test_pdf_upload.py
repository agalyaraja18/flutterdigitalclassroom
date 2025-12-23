#!/usr/bin/env python
"""
Test script to diagnose PDF upload issues
"""
import requests
import os

# Configuration
BASE_URL = "http://localhost:8000/api"
AUTH_TOKEN = "bd54048f70be74bef0ef86f8c7b30b15dc364fd4"  # Replace with your token
PDF_FILE_PATH = r"D:\abishek\Flutterproject\test_document.pdf"

def test_pdf_upload():
    """Test PDF upload endpoint"""

    print("=" * 60)
    print("Testing PDF Upload Endpoint")
    print("=" * 60)

    # Check if PDF exists
    if not os.path.exists(PDF_FILE_PATH):
        print(f"[ERROR] PDF file not found: {PDF_FILE_PATH}")
        return

    print(f"[OK] PDF file found: {PDF_FILE_PATH}")
    print(f"     File size: {os.path.getsize(PDF_FILE_PATH)} bytes")

    # Prepare request
    url = f"{BASE_URL}/pdf-analyzer/upload/"
    headers = {
        "Authorization": f"Token {AUTH_TOKEN}"
    }

    files = {
        'pdf_file': ('test_document.pdf', open(PDF_FILE_PATH, 'rb'), 'application/pdf')
    }

    data = {
        'title': 'Test Document Upload'
    }

    print(f"\n[REQUEST] Sending to: {url}")
    print(f"          Headers: {headers}")
    print(f"          Data: {data}")

    try:
        response = requests.post(
            url,
            headers=headers,
            files=files,
            data=data,
            timeout=60
        )

        print(f"\n[RESPONSE] Status: {response.status_code}")
        print(f"           Headers: {dict(response.headers)}")
        print(f"\n[RESPONSE BODY]")
        print(response.text)

        if response.status_code == 201:
            print("\n[SUCCESS] PDF uploaded successfully!")
        else:
            print(f"\n[FAILED] Status {response.status_code}")

    except requests.exceptions.ConnectionError:
        print("\n[ERROR] CONNECTION: Django server is not running on localhost:8000")
    except Exception as e:
        print(f"\n[ERROR] {type(e).__name__}: {str(e)}")
    finally:
        # Close file
        if 'files' in locals():
            files['pdf_file'][1].close()

if __name__ == "__main__":
    test_pdf_upload()
