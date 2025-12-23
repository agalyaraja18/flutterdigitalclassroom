# 🚀 Quick Start Commands

## Backend Setup & Run

### Windows PowerShell:
```powershell
# Terminal 1 - Django Backend
cd lms_backend
.\venv\Scripts\Activate
python manage.py migrate
python manage.py runserver
```

### Linux/Mac:
```bash
# Terminal 1 - Django Backend
cd lms_backend
source venv/bin/activate
python manage.py migrate
python manage.py runserver
```

**Backend will run on:** http://127.0.0.1:8000/

---

## Frontend Setup & Run

### All Platforms:
```bash
# Terminal 2 - Flutter App
cd lms_flutter_app
flutter pub get
flutter run -d chrome
```

**Or for specific platforms:**
```bash
flutter run -d android    # Android emulator
flutter run -d ios        # iOS simulator (Mac only)
flutter run               # Default device
```

---

## Complete Setup (First Time)

### Backend:
```bash
cd lms_backend
python -m venv venv                    # Create venv (if not exists)
.\venv\Scripts\Activate                # Windows
# source venv/bin/activate             # Linux/Mac
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser       # Optional
python manage.py runserver
```

### Frontend:
```bash
cd lms_flutter_app
flutter pub get
flutter doctor                         # Check setup
flutter run -d chrome
```

---

## Essential Commands

### Backend:
| Command | Description |
|---------|-------------|
| `python manage.py migrate` | Run database migrations |
| `python manage.py runserver` | Start Django server |
| `python manage.py createsuperuser` | Create admin user |
| `python manage.py cleanup_expired_documents` | Clean expired PDFs |

### Frontend:
| Command | Description |
|---------|-------------|
| `flutter pub get` | Install dependencies |
| `flutter run` | Run app on default device |
| `flutter run -d chrome` | Run on Chrome browser |
| `flutter clean` | Clean build files |
| `flutter doctor` | Check Flutter setup |

---

## Two Terminal Setup

**Terminal 1 (Backend):**
```bash
cd lms_backend
.\venv\Scripts\Activate
python manage.py runserver
```

**Terminal 2 (Frontend):**
```bash
cd lms_flutter_app
flutter run -d chrome
```

---

## Verify Setup

1. **Backend:** Open http://127.0.0.1:8000/ - Should see API docs
2. **Frontend:** App should launch and show login screen
3. **Connection:** Try logging in through the app

---

**Full documentation:** See `SETUP_GUIDE.md` for detailed instructions.

