from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from ...models.booking import (
    BookingRequest,
    BookingRequestCreate,
    BookingRequestRead,
    BookingStatus,
    BookingStatusUpdate,
)
from ...models.service import ServiceListing
from ...models.user import User
from ..deps import get_current_active_user, get_db

router = APIRouter(prefix="/bookings", tags=["bookings"])


@router.post("/", response_model=BookingRequestRead, status_code=status.HTTP_201_CREATED)
def create_booking(
    payload: BookingRequestCreate,
    current_user: User = Depends(get_current_active_user),
    session: Session = Depends(get_db),
) -> BookingRequest:
    listing = session.get(ServiceListing, payload.listing_id)
    if not listing or listing.provider_id != payload.provider_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid listing/provider")

    booking = BookingRequest(
        listing_id=payload.listing_id,
        provider_id=payload.provider_id,
        requester_id=current_user.id,
        scheduled_at=payload.scheduled_at,
        duration_hours=payload.duration_hours,
        location=payload.location,
        notes=payload.notes,
        total_price=payload.total_price,
    )
    session.add(booking)
    session.commit()
    session.refresh(booking)
    return BookingRequestRead.model_validate(booking)


@router.get("/", response_model=list[BookingRequestRead])
def list_bookings(
    role: str = "requester",
    status_filter: BookingStatus | None = None,
    current_user: User = Depends(get_current_active_user),
    session: Session = Depends(get_db),
) -> list[BookingRequest]:
    query = select(BookingRequest)
    if role == "provider":
        query = query.where(BookingRequest.provider_id == current_user.id)
    else:
        query = query.where(BookingRequest.requester_id == current_user.id)

    if status_filter:
        query = query.where(BookingRequest.status == status_filter)

    bookings = session.exec(query).all()
    return [BookingRequestRead.model_validate(item) for item in bookings]


@router.patch("/{booking_id}/status", response_model=BookingRequestRead)
def update_booking_status(
    booking_id: int,
    payload: BookingStatusUpdate,
    current_user: User = Depends(get_current_active_user),
    session: Session = Depends(get_db),
) -> BookingRequest:
    booking = session.get(BookingRequest, booking_id)
    if not booking:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")

    is_provider = booking.provider_id == current_user.id
    is_requester = booking.requester_id == current_user.id

    if not (is_provider or is_requester):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed")

    valid_transitions = {
        BookingStatus.REQUESTED: {BookingStatus.ACCEPTED, BookingStatus.CANCELLED},
        BookingStatus.ACCEPTED: {BookingStatus.IN_PROGRESS, BookingStatus.CANCELLED},
        BookingStatus.IN_PROGRESS: {BookingStatus.COMPLETED, BookingStatus.CANCELLED},
        BookingStatus.COMPLETED: set(),
        BookingStatus.CANCELLED: set(),
    }

    if payload.new_status not in valid_transitions[booking.status]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid status transition")

    booking.status = payload.new_status
    session.add(booking)
    session.commit()
    session.refresh(booking)
    return BookingRequestRead.model_validate(booking)

