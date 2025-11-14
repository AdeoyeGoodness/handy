# Backend Architecture Overview

## Framework Selection
- **Framework**: FastAPI (Python 3.12)
- **ASGI Server**: Uvicorn
- **ORM**: SQLModel (SQLAlchemy core) with Alembic migrations
- **Database**: PostgreSQL 15
- **Auth**: OAuth2 password flow issuing JWT access/refresh tokens
- **Task Queue**: Celery + Redis for background jobs (notifications, email)
- **Object Storage**: Amazon S3 (or MinIO in development) for user/service images

## Core Services
1. **Authentication Service**
   - Handles phone-first registration & login, password reset, token refresh, and social sign-in hooks.
2. **User Profile Service**
   - Stores citizen profiles, roles (`SERVICE_PROVIDER`, `SERVICE_SEEKER`, `ADMIN`), skill tags, certifications.
3. **Service Listings Service**
   - Manages categories, service offerings, pricing options, availability schedules.
4. **Booking & Job Management Service**
   - Request/offer workflow, status updates (`REQUESTED`, `ACCEPTED`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`), payment intents.
5. **Reviews & Ratings Service**
   - Post-completion feedback, dispute flags, reputation scoring.
6. **Messaging Service**
   - Real-time chat powered by WebSockets (FastAPI + PostgreSQL pub/sub or Redis streams).
7. **Notification Service**
   - Push notifications (FCM/APNs), email, and in-app alerts.

## Data Model Draft
- **User**
  - `id`, `email`, `password_hash`, `role`, `first_name`, `last_name`, `phone`, `avatar_url`, `bio`, `rating_avg`, `created_at`, `updated_at`
- **UserSkill**
  - `id`, `user_id`, `skill_tag`
- **ServiceCategory**
  - `id`, `name`, `description`, `icon`
- **ServiceListing**
  - `id`, `provider_id`, `category_id`, `title`, `description`, `base_price`, `pricing_unit`, `coverage_area`, `is_active`, `cover_image_url`, `created_at`, `updated_at`
- **ServiceMedia**
  - `id`, `listing_id`, `media_url`, `media_type`
- **BookingRequest**
  - `id`, `listing_id`, `requester_id`, `provider_id`, `scheduled_at`, `duration_hours`, `location`, `status`, `total_price`, `payment_status`, `notes`, `created_at`, `updated_at`
- **BookingTimelineEvent**
  - `id`, `booking_id`, `event_type`, `metadata`, `created_at`
- **Review**
  - `id`, `booking_id`, `reviewer_id`, `reviewee_id`, `rating`, `comment`, `created_at`
- **MessageThread**
  - `id`, `booking_id` (nullable), `initiator_id`, `receiver_id`, `last_message_at`
- **Message**
  - `id`, `thread_id`, `sender_id`, `content`, `message_type`, `read_at`, `sent_at`
- **Notification**
  - `id`, `user_id`, `type`, `payload`, `is_read`, `created_at`
- **AuditLog**
  - `id`, `actor_id`, `action`, `target_type`, `target_id`, `metadata`, `created_at`

## API Endpoint Outline

### Auth (`/api/v1/auth`)
- `POST /register`
- `POST /login`
- `POST /refresh`
- `POST /password/reset/request`
- `POST /password/reset/confirm`

### Users (`/api/v1/users`)
- `GET /me`
- `PATCH /me`
- `POST /me/avatar`
- `GET /providers?category=&location=&rating>=`
- `GET /{user_id}`

### Services (`/api/v1/services`)
- `GET /categories`
- `POST /categories` (admin)
- `GET /listings`
- `POST /listings`
- `PATCH /listings/{listing_id}`
- `DELETE /listings/{listing_id}`

### Bookings (`/api/v1/bookings`)
- `POST /`
- `GET /?role=provider|requester&status=`
- `GET /{booking_id}`
- `PATCH /{booking_id}/status`
- `POST /{booking_id}/timeline`

### Reviews (`/api/v1/reviews`)
- `POST /`
- `GET /?user_id=`
- `GET /{review_id}`

### Messaging (`/api/v1/messages`)
- `GET /threads`
- `POST /threads`
- `GET /threads/{thread_id}`
- `POST /threads/{thread_id}/messages`
- `GET /ws` (WebSocket endpoint)

### Notifications (`/api/v1/notifications`)
- `GET /`
- `PATCH /{notification_id}/read`
- `POST /device-tokens`

## Deployment Targets
- Development: Docker Compose (FastAPI, PostgreSQL, Redis, MinIO, Mailhog)
- Production: Managed PostgreSQL (e.g., AWS RDS), Redis (Elasticache), FastAPI on AWS Fargate or DigitalOcean App Platform, S3 bucket, CloudFront CDN.
- Observability: Prometheus + Grafana, Sentry for error tracking, structured logging to CloudWatch.

