import requests
import json

def test_login():
    """Test the login endpoint directly"""
    login_url = "http://localhost:8000/api/auth/login/"

    # Test with the credentials shown in console
    login_data = {"username": "Abishek", "password": "Abi@142004"}

    print(f"Testing login with: {login_data}")
    print(f"URL: {login_url}")

    try:
        response = requests.post(login_url, json=login_data)
        print(f"Status Code: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        print(f"Response Text: {response.text}")

        if response.status_code == 200:
            result = response.json()
            print("Login successful!")
            print(f"Token: {result.get('token', 'No token')}")
            print(f"User data: {result.get('user', 'No user data')}")
        else:
            print("Login failed!")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_login()