from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from ...models.service import (
    ServiceCategory,
    ServiceListing,
    ServiceListingCreate,
    ServiceListingRead,
)
from ..deps import get_current_active_provider, get_current_active_user, get_db

router = APIRouter(prefix="/services", tags=["services"])


@router.get("/categories", response_model=list[ServiceCategory])
def list_categories(session: Session = Depends(get_db)) -> list[ServiceCategory]:
    return session.exec(select(ServiceCategory)).all()


@router.post("/categories", response_model=ServiceCategory, status_code=status.HTTP_201_CREATED)
def create_category(
    payload: ServiceCategory,
    session: Session = Depends(get_db),
) -> ServiceCategory:
    existing = session.exec(select(ServiceCategory).where(ServiceCategory.name == payload.name)).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Category already exists")
    session.add(payload)
    session.commit()
    session.refresh(payload)
    return payload


@router.get("/listings", response_model=list[ServiceListingRead])
def list_listings(session: Session = Depends(get_db)) -> list[ServiceListing]:
    listings = session.exec(select(ServiceListing).where(ServiceListing.is_active == True)).all()  # noqa: E712
    return [ServiceListingRead.model_validate(item) for item in listings]


@router.post("/listings", response_model=ServiceListingRead, status_code=status.HTTP_201_CREATED)
def create_listing(
    payload: ServiceListingCreate,
    provider=Depends(get_current_active_provider),
    session: Session = Depends(get_db),
) -> ServiceListing:
    listing = ServiceListing(**payload.model_dump(), provider_id=provider.id)
    session.add(listing)
    session.commit()
    session.refresh(listing)
    return ServiceListingRead.model_validate(listing)


@router.patch("/listings/{listing_id}", response_model=ServiceListingRead)
def update_listing(
    listing_id: int,
    payload: ServiceListingCreate,
    provider=Depends(get_current_active_provider),
    session: Session = Depends(get_db),
) -> ServiceListing:
    listing = session.get(ServiceListing, listing_id)
    if not listing or listing.provider_id != provider.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")

    for key, value in payload.model_dump().items():
        setattr(listing, key, value)
    session.add(listing)
    session.commit()
    session.refresh(listing)
    return ServiceListingRead.model_validate(listing)


@router.delete("/listings/{listing_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_listing(
    listing_id: int,
    provider=Depends(get_current_active_provider),
    session: Session = Depends(get_db),
) -> None:
    listing = session.get(ServiceListing, listing_id)
    if not listing or listing.provider_id != provider.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")
    session.delete(listing)
    session.commit()

