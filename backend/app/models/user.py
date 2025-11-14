from datetime import datetime
from enum import Enum
from typing import TYPE_CHECKING, Optional

from sqlmodel import Field, Relationship, SQLModel

if TYPE_CHECKING:
    from .address import Address, AddressCreate
    from .availability import Availability, AvailabilityCreate


class UserRole(str, Enum):
    SERVICE_PROVIDER = "SERVICE_PROVIDER"
    SERVICE_SEEKER = "SERVICE_SEEKER"
    ADMIN = "ADMIN"


class UserBase(SQLModel):
    phone: str = Field(index=True, unique=True, max_length=11)
    first_name: str
    last_name: str
    email: Optional[str] = Field(default=None, index=True)
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    role: UserRole = Field(default=UserRole.SERVICE_SEEKER)


class User(UserBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    password_hash: str
    rating_avg: float = Field(default=0, ge=0, le=5)
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    skills: list["UserSkill"] = Relationship(back_populates="user")
    address: Optional["Address"] = Relationship(back_populates="user", sa_relationship_kwargs={"uselist": False})
    availabilities: list["Availability"] = Relationship(back_populates="user")


class UserPublic(UserBase):
    id: int
    rating_avg: float


class UserCreate(UserBase):
    password: str
    email: Optional[str] = None
    address: Optional["AddressCreate"] = None
    availability: Optional[list["AvailabilityCreate"]] = None


class UserRead(UserPublic):
    pass


class UserSkill(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    skill_tag: str = Field(index=True)

    user: Optional[User] = Relationship(back_populates="skills")

