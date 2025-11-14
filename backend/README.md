# Citizen Service Backend

FastAPI-powered backend for the citizen-to-citizen service marketplace.

## Getting Started

1. Create a virtual environment and install dependencies:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # Windows: .venv\Scripts\activate
   pip install -e ".[dev]"
   ```

2. Create a `.env` file:
   ```
   SECRET_KEY=replace-me
   DATABASE_URL=sqlite:///./database.db
   ```

3. Run the API:
   ```bash
   uvicorn app.main:app --reload
   ```

## Features

- JWT authentication with access/refresh tokens (phone number + password).
- User registration & profile retrieval.
- Service categories and provider listings.
- Booking creation, listing, and status updates.
- Simple messaging threads for bookings or direct conversations.
- CORS enabled for Flutter client integration.

## Testing

```bash
pytest
```

## Further Work

- Implement Alembic migrations and seed scripts.
- Integrate Redis and Celery workers.
- Add payment processing and notifications.
- Harden validation and error handling.

