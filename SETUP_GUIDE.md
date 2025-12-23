# Complete Setup Guide - Backend & Frontend

## 📋 Prerequisites

### Backend:
- Python 3.8+ installed
- pip (Python package manager)
- Virtual environment (recommended)

### Frontend:
- Flutter SDK 3.0.0+ installed
- Dart SDK (comes with Flutter)
- Android Studio / VS Code with Flutter extensions (optional but recommended)

---

## 🔧 Backend Setup

### Step 1: Navigate to Backend Directory
```bash
cd lms_backend
```

### Step 2: Create/Activate Virtual Environment (Recommended)
**Windows:**
```powershell
# Create virtual environment
python -m venv venv

# Activate virtual environment
.\venv\Scripts\Activate
```

**Linux/Mac:**
```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate
```

### Step 3: Install Dependencies
```bash
pip install -r requirements.txt
```

### Step 4: Verify Environment Variables
Check that `.env` file exists and contains:
```
SECRET_KEY=django-insecure-your-secret-key-here-change-in-production
GEMINI_API_KEY=REDACTED_API_KEY
DEBUG=True
AI_API_KEY=REDACTED_API_KEY
```

### Step 5: Run Database Migrations
```bash
python manage.py migrate
```

### Step 6: Create Superuser (Optional - for admin access)
```bash
python manage.py createsuperuser
```
Follow the prompts to create an admin account.

### Step 7: Start Backend Server
```bash
python manage.py runserver
```

The backend will be available at: **http://127.0.0.1:8000/**

**Verify it's running:**
- Open browser: http://127.0.0.1:8000/
- You should see the API root documentation

---

## 📱 Frontend Setup (Flutter)

### Step 1: Navigate to Flutter App Directory
```bash
cd lms_flutter_app
```

### Step 2: Get Flutter Dependencies
```bash
flutter pub get
```

### Step 3: Verify Flutter Installation
```bash
flutter doctor
```
This will check if Flutter is properly installed and configured.

### Step 4: Check Available Devices
```bash
flutter devices
```
This shows available emulators/simulators or connected devices.

### Step 5: Run the Flutter App

**Option A: Run on Web**
```bash
flutter run -d chrome
```

**Option B: Run on Android Emulator**
```bash
# First, start an Android emulator from Android Studio
# Then run:
flutter run
```

**Option C: Run on iOS Simulator (Mac only)**
```bash
# First, start an iOS simulator
# Then run:
flutter run
```

**Option D: Run on Connected Device**
```bash
# Connect your phone via USB with USB debugging enabled
flutter run
```

---

## 🔗 Backend & Frontend Connection

### Important Notes:

1. **Backend must be running** before starting the Flutter app
2. **API Base URL** is configured in:
   - File: `lms_flutter_app/lib/core/constants/app_constants.dart`
   - Current setting: `http://localhost:8000/api/`

3. **For Android Emulator:**
   - The app automatically converts `localhost` to `10.0.2.2` for Android emulator
   - No changes needed

4. **For Physical Device:**
   - Change `localhost` to your computer's IP address
   - Example: `http://192.168.1.100:8000/api/`
   - Find your IP:
     - **Windows:** `ipconfig` (look for IPv4 Address)
     - **Linux/Mac:** `ifconfig` or `ip addr`

---

## 🧪 Testing the Setup

### Test Backend:
1. Open browser: http://127.0.0.1:8000/
2. You should see API documentation
3. Test login endpoint: http://127.0.0.1:8000/api/auth/login/

### Test Frontend:
1. Launch the Flutter app
2. You should see the login screen
3. Try logging in with your credentials

---

## 📝 Common Commands Reference

### Backend Commands:
```bash
# Activate virtual environment (Windows)
.\venv\Scripts\Activate

# Activate virtual environment (Linux/Mac)
source venv/bin/activate

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Start server
python manage.py runserver

# Start server on specific port
python manage.py runserver 8000

# Cleanup expired PDF documents
python manage.py cleanup_expired_documents

# Check migrations status
python manage.py showmigrations
```

### Frontend Commands:
```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Run on specific device
flutter run -d chrome
flutter run -d android
flutter run -d ios

# Build APK (Android)
flutter build apk

# Build iOS (Mac only)
flutter build ios

# Clean build
flutter clean
flutter pub get

# Check for issues
flutter doctor
flutter analyze
```

---

## 🐛 Troubleshooting

### Backend Issues:

**Port already in use:**
```bash
# Use a different port
python manage.py runserver 8001
```

**Migration errors:**
```bash
# Reset migrations (CAUTION: deletes data)
python manage.py migrate pdf_analyzer zero
python manage.py migrate pdf_analyzer
```

**Module not found:**
```bash
# Reinstall dependencies
pip install -r requirements.txt
```

### Frontend Issues:

**Dependencies not installing:**
```bash
flutter clean
flutter pub get
```

**Build errors:**
```bash
flutter clean
flutter pub get
flutter run
```

**Can't connect to backend:**
- Ensure backend is running
- Check API URL in `app_constants.dart`
- For physical device, use computer's IP instead of localhost
- Check firewall settings

**Android emulator connection:**
- The app automatically handles `localhost` → `10.0.2.2` conversion
- No manual changes needed

---

## 🚀 Quick Start (All-in-One)

### Terminal 1 - Backend:
```bash
cd lms_backend
.\venv\Scripts\Activate  # Windows
# or: source venv/bin/activate  # Linux/Mac
python manage.py migrate
python manage.py runserver
```

### Terminal 2 - Frontend:
```bash
cd lms_flutter_app
flutter pub get
flutter run -d chrome
```

---

## 📚 Additional Resources

- **Backend API Docs:** http://127.0.0.1:8000/ (when server is running)
- **Django Admin:** http://127.0.0.1:8000/admin/
- **Flutter Docs:** https://flutter.dev/docs
- **Django Docs:** https://docs.djangoproject.com/

---

## ✅ Verification Checklist

- [ ] Backend dependencies installed
- [ ] `.env` file configured with API keys
- [ ] Database migrations run successfully
- [ ] Backend server running on port 8000
- [ ] Flutter dependencies installed
- [ ] Flutter app runs without errors
- [ ] Can login through Flutter app
- [ ] API endpoints accessible

---

## 🎯 Next Steps

1. **Create test users** via Django admin or registration endpoint
2. **Test PDF upload** functionality
3. **Test PDF Analysis** module
4. **Test Quiz** creation and taking
5. **Explore the admin panel** for managing data

---

**Need Help?** Check the individual setup guides:
- Backend: `lms_backend/PDF_ANALYSIS_SETUP.md`
- Backend: `lms_backend/BACKEND_SETUP.md`
- Frontend: `lms_flutter_app/README.md`

