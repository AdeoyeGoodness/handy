# Deployment Checklist

## Pre-flight
- [ ] Verify backend tests: `cd backend && pytest`.
- [ ] Run linters: `ruff check app` and `mypy app`.
- [ ] Ensure database migrations are up-to-date (Alembic).
- [ ] Confirm `.env` and secrets are configured for target environment.

## Backend Deployment
1. Build container: `docker build -t citizen-service-backend ./backend`.
2. Push image to registry (ECR, Docker Hub, etc.).
3. Apply infrastructure changes (Terraform/CloudFormation) if needed.
4. Run database migrations automatically on deploy.
5. Configure health checks to hit `/healthz`.

## Flutter Release
- [ ] Update backend base URL in `lib/core/config.dart` to staging/production.
- [ ] `flutter build apk --release` (Android) or `flutter build ipa` (iOS).
- [ ] Distribute build via Firebase App Distribution/TestFlight.
- [ ] Tag release in version control and document changelog.

## Post-deploy
- [ ] Smoke test critical flows (auth, listing, booking, messaging).
- [ ] Monitor logs, metrics, and crash reports.
- [ ] Collect user feedback and file issues.

