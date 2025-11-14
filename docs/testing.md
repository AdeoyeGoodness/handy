# Testing & Quality Strategy

## Backend
- **Unit & Integration Tests**: Pytest suite under `backend/tests` exercises auth, service, booking, and messaging paths via FastAPI `TestClient`.
- **Static Analysis**: Run Ruff (`ruff check app`) and MyPy (`mypy app`) to catch linting and typing issues.
- **CI Suggestion**: Configure GitHub Actions to run `pytest`, `ruff`, and `mypy` on every pull request.

## Flutter Client
- **Widget Tests**: Add coverage for view models (Riverpod providers) and UI widgets with `flutter test`.
- **Golden Tests**: Capture core screens (login, home dashboard) for regression detection.
- **Integration Tests**: Use `flutter test integration_test` with a mocked backend (or the staging API).

## Manual QA Checklist
- Registration/login flow (phone number + password) with invalid credentials.
- Create service listing as provider, verify seeker can discover and book.
- Booking status transitions (request -> accept -> complete).
- Messaging between seeker/provider around a booking.
- Profile updates and logout experience.

## Monitoring & Observability
- Backend: Integrate Sentry + Prometheus/Grafana for error tracking and metrics.
- Flutter: Add Firebase Crashlytics and Analytics for crash reporting and usage patterns.
- Logging: Use structured JSON logging in production to improve traceability.

