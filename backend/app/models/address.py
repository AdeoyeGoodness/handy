from datetime import datetime
from typing import Optional

from sqlmodel import Field, Relationship, SQLModel


class AddressBase(SQLModel):
    street: str
    city: str
    state: str
    postal_code: Optional[str] = None
    notes: Optional[str] = None


class Address(AddressBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id", unique=True, index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    user: Optional["User"] = Relationship(back_populates="address")


class AddressCreate(AddressBase):
    pass


class AddressRead(AddressBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

