from datetime import datetime, time
from enum import Enum
from typing import Optional

from sqlmodel import Field, Relationship, SQLModel


class DayOfWeek(str, Enum):
    MONDAY = "Monday"
    TUESDAY = "Tuesday"
    WEDNESDAY = "Wednesday"
    THURSDAY = "Thursday"
    FRIDAY = "Friday"
    SATURDAY = "Saturday"
    SUNDAY = "Sunday"


class AvailabilityBase(SQLModel):
    day_of_week: DayOfWeek
    start_time: time
    end_time: time
    is_available: bool = Field(default=True)


class Availability(AvailabilityBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id", index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    user: Optional["User"] = Relationship(back_populates="availabilities")


class AvailabilityCreate(AvailabilityBase):
    pass


class AvailabilityRead(AvailabilityBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

