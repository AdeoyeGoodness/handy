from datetime import datetime
from typing import Optional

from sqlmodel import Field, Relationship, SQLModel

from .user import User


class ServiceCategory(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(unique=True, index=True)
    description: Optional[str] = None
    icon: Optional[str] = None

    listings: list["ServiceListing"] = Relationship(back_populates="category")


class ServiceListingBase(SQLModel):
    title: str
    description: str
    base_price: float = Field(gt=0)
    pricing_unit: str = Field(default="hour")
    coverage_area: Optional[str] = None
    is_active: bool = Field(default=True)


class ServiceListing(ServiceListingBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    provider_id: int = Field(foreign_key="user.id")
    category_id: int = Field(foreign_key="servicecategory.id")
    cover_image_url: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    category: Optional[ServiceCategory] = Relationship(back_populates="listings")
    provider: Optional[User] = Relationship(sa_relationship_kwargs={"lazy": "joined"})
    media_items: list["ServiceMedia"] = Relationship(back_populates="listing")


class ServiceListingCreate(ServiceListingBase):
    category_id: int


class ServiceListingRead(ServiceListingBase):
    id: int
    provider_id: int
    category_id: int
    cover_image_url: Optional[str]


class ServiceMedia(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    listing_id: int = Field(foreign_key="servicelisting.id")
    media_url: str
    media_type: str = Field(default="image")

    listing: Optional[ServiceListing] = Relationship(back_populates="media_items")

