# Deployment & Testing Guide

## Local Staging Environment

1. Ensure Docker Desktop is running.
2. From the repository root:
   ```bash
   cd deploy
   docker compose up --build
   ```
3. Backend API available at `http://localhost:8000`.
4. PostgreSQL credentials: user `handy`, password `handy`, database `handy`.

## Running Tests

### Backend
```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt -r requirements-dev.txt
pytest
```

### Flutter
```bash
cd client
flutter test
```

## Beta Feedback Loop

1. Deploy backend to a cloud environment (e.g. Railway, Render, AWS Fargate) using the Dockerfile.
2. Build Flutter app via `flutter build apk` and distribute with Firebase App Distribution/TestFlight.
3. Instrument backend with Sentry and frontend with Firebase Analytics to collect crash/usage data.
4. Gather user feedback through in-app prompts or Google Forms; track issues in GitHub Projects.
5. Iterate on UX, add push notifications, and prepare marketing assets prior to public release.

