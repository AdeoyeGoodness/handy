from datetime import datetime, timedelta

from fastapi.testclient import TestClient


def auth_headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def test_full_service_flow(client: TestClient) -> None:
    # Seed category
    category_resp = client.post(
        "/api/v1/services/categories",
        json={"name": "Cleaning", "description": "Home & office cleaning"},
    )
    assert category_resp.status_code == 201
    category_id = category_resp.json()["id"]

    # Register provider
    provider_payload = {
        "phone": "08000000011",
        "email": "provider@example.com",
        "password": "Passw0rd!",
        "first_name": "Pro",
        "last_name": "Helper",
        "role": "SERVICE_PROVIDER",
    }
    reg_provider = client.post("/api/v1/auth/register", json=provider_payload)
    assert reg_provider.status_code == 201

    provider_login = client.post(
        "/api/v1/auth/login",
        data={"username": provider_payload["phone"], "password": provider_payload["password"]},
    )
    assert provider_login.status_code == 200
    provider_token = provider_login.json()["access_token"]

    listing_resp = client.post(
        "/api/v1/services/listings",
        json={
          "title": "Apartment Cleaning",
          "description": "Thorough cleaning for apartments",
          "base_price": 50,
          "pricing_unit": "hour",
          "category_id": category_id,
          "coverage_area": "Downtown",
        },
        headers=auth_headers(provider_token),
    )
    assert listing_resp.status_code == 201
    listing_id = listing_resp.json()["id"]

    # Register seeker
    seeker_payload = {
        "phone": "08000000022",
        "email": "seeker@example.com",
        "password": "Passw0rd!",
        "first_name": "Home",
        "last_name": "Owner",
        "role": "SERVICE_SEEKER",
    }
    reg_seeker = client.post("/api/v1/auth/register", json=seeker_payload)
    assert reg_seeker.status_code == 201

    seeker_login = client.post(
        "/api/v1/auth/login",
        data={"username": seeker_payload["phone"], "password": seeker_payload["password"]},
    )
    assert seeker_login.status_code == 200
    seeker_token = seeker_login.json()["access_token"]

    # Create booking
    booking_resp = client.post(
        "/api/v1/bookings/",
        json={
            "listing_id": listing_id,
            "provider_id": reg_provider.json()["id"],
            "scheduled_at": (datetime.utcnow() + timedelta(days=1)).isoformat(),
            "duration_hours": 2,
            "location": "123 Main St",
            "notes": "Please bring eco-friendly supplies",
            "total_price": 100,
        },
        headers=auth_headers(seeker_token),
    )
    assert booking_resp.status_code == 201
    booking_id = booking_resp.json()["id"]

    # Provider accepts booking
    status_resp = client.patch(
        f"/api/v1/bookings/{booking_id}/status",
        json={"new_status": "ACCEPTED"},
        headers=auth_headers(provider_token),
    )
    assert status_resp.status_code == 200
    assert status_resp.json()["status"] == "ACCEPTED"

    # Messaging between seeker and provider
    thread_resp = client.post(
        "/api/v1/messages/threads",
        json={"receiver_id": reg_provider.json()["id"]},
        headers=auth_headers(seeker_token),
    )
    assert thread_resp.status_code == 201
    thread_id = thread_resp.json()["id"]

    message_resp = client.post(
        f"/api/v1/messages/threads/{thread_id}/messages",
        json={"content": "Looking forward to the service!"},
        headers=auth_headers(seeker_token),
    )
    assert message_resp.status_code == 201

    messages = client.get(
        f"/api/v1/messages/threads/{thread_id}/messages",
        headers=auth_headers(provider_token),
    )
    assert messages.status_code == 200
    assert len(messages.json()) == 1

