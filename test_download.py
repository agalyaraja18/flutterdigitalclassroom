import requests
import os

def test_audio_download():
    """Test downloading the converted audio file"""
    # Login to get auth token
    login_url = "http://localhost:8000/api/auth/login/"
    login_data = {"username": "admin", "password": "admin123"}

    print("Logging in...")
    response = requests.post(login_url, json=login_data)

    if response.status_code == 200:
        auth_token = response.json()['token']
        print("Login successful!")

        # Get document details
        doc_url = "http://localhost:8000/api/pdf/documents/2/"
        headers = {'Authorization': f'Token {auth_token}'}

        response = requests.get(doc_url, headers=headers)
        if response.status_code == 200:
            doc_data = response.json()
            print(f"Document: {doc_data['title']}")
            print(f"Status: {doc_data['conversion_status']}")

            if doc_data['audio_file']:
                # Download the audio file
                audio_url = f"http://localhost:8000{doc_data['audio_file']}"
                print(f"Downloading from: {audio_url}")

                audio_response = requests.get(audio_url, headers=headers)
                if audio_response.status_code == 200:
                    # Save the downloaded file
                    download_path = "downloaded_audio.wav"
                    with open(download_path, 'wb') as f:
                        f.write(audio_response.content)

                    file_size = os.path.getsize(download_path)
                    print(f"Audio file downloaded successfully!")
                    print(f"File size: {file_size} bytes")
                    print(f"Saved as: {download_path}")

                    return True
                else:
                    print(f"Failed to download audio: {audio_response.status_code}")
                    return False
            else:
                print("No audio file available")
                return False
        else:
            print(f"Failed to get document: {response.status_code}")
            return False
    else:
        print(f"Login failed: {response.status_code}")
        return False

if __name__ == "__main__":
    test_audio_download()