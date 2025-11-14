# Citizen Service Marketplace

Cross-platform platform enabling citizens to offer and request services (handymen, cleaners, mechanics, etc.).

## Project Structure
- `backend/` – FastAPI backend (auth, services, bookings, messaging).
- `client/` – Flutter app for Android/iOS/web with Riverpod state management.
- `deploy/` – Docker Compose staging environment & deployment docs.
- `docs/` – Architecture, testing, and deployment notes.

## Quick Start
1. **Backend**
   ```bash
   cd backend
   python -m venv .venv
   source .venv/bin/activate  # Windows: .venv\Scripts\activate
   pip install -r requirements.txt
   uvicorn app.main:app --reload
   ```
2. **Flutter Client**
   ```bash
   cd client
   flutter pub get
   flutter run
   ```

Ensure `lib/core/config.dart` points to the running backend (`http://localhost:8000/api/v1` by default).

Authentication uses phone number + password for both service providers and seekers.

## Testing
- Backend: `cd backend && pip install -r requirements-dev.txt && pytest`
- Flutter: `cd client && flutter test`

More guidance in `docs/testing.md`.

## Deployment
- Local staging via Docker Compose: `cd deploy && docker compose up --build`
- Detailed checklists in `docs/deployment_checklist.md`.

