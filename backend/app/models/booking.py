from datetime import datetime
from enum import Enum
from typing import Optional

from sqlmodel import Field, Relationship, SQLModel


class BookingStatus(str, Enum):
    REQUESTED = "REQUESTED"
    ACCEPTED = "ACCEPTED"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"


class BookingRequestBase(SQLModel):
    scheduled_at: datetime
    duration_hours: float
    location: str
    notes: Optional[str] = None


class BookingRequest(BookingRequestBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    listing_id: int = Field(foreign_key="servicelisting.id")
    requester_id: int = Field(foreign_key="user.id")
    provider_id: int = Field(foreign_key="user.id")
    status: BookingStatus = Field(default=BookingStatus.REQUESTED)
    total_price: float
    payment_status: str = Field(default="PENDING")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class BookingRequestCreate(BookingRequestBase):
    listing_id: int
    provider_id: int
    total_price: float


class BookingRequestRead(BookingRequestBase):
    id: int
    listing_id: int
    requester_id: int
    provider_id: int
    status: BookingStatus
    total_price: float
    payment_status: str


class BookingStatusUpdate(SQLModel):
    new_status: BookingStatus

