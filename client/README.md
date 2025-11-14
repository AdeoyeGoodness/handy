# Citizen Service Flutter Client

Flutter application for the citizen-to-citizen service marketplace.

## Prerequisites
- Flutter 3.19 or newer
- Dart 3.3 or newer
- Backend API running locally at `http://localhost:8000/api/v1` (configurable in `lib/core/config.dart`)

## Setup
```bash
flutter pub get
flutter run
```

## Features Implemented
- Email/password registration & login (JWT persisted with SharedPreferences).
- Home discovery view with categories & service listings.
- Booking request flow with scheduling, location, and notes.
- Booking dashboard with role toggles (requests vs. jobs).
- Messaging threads with send & receive chat interface.
- Profile view with logout.

## Customisation
- Update `AppConfig` in `lib/core/config.dart` to point to a different backend URL.
- Add assets in `assets/images/` and update widgets with richer visuals.
- Extend state management via Riverpod providers defined in `lib/core/providers.dart`.

