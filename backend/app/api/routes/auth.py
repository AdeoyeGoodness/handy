from datetime import timedelta
import re

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlmodel import Session, select

from ...core.config import get_settings
from ...core.database import get_session
from ...core.security import create_token, decode_token, get_password_hash, verify_password
from ...models.address import Address, AddressCreate
from ...models.availability import Availability, AvailabilityCreate, DayOfWeek
from ...models.user import User, UserCreate, UserRead, UserRole

router = APIRouter(prefix="/auth", tags=["auth"])
settings = get_settings()


@router.post("/register", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def register_user(payload: UserCreate, session: Session = Depends(get_session)) -> User:
    phone_value = payload.phone.strip()
    existing_phone = session.exec(select(User).where(User.phone == phone_value)).first()
    if existing_phone:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Phone already in use")

    if len(phone_value) != 11 or not phone_value.isdigit():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone number must be 11 digits",
        )

    password_value = payload.password
    if len(password_value) < 8 or not re.search(r"[A-Z]", password_value) or not re.search(
        r"[0-9]", password_value
    ) or not re.search(r"[^A-Za-z0-9]", password_value):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must be at least 8 characters with a capital letter, number, and symbol",
        )

    if payload.email:
        email_value = payload.email.lower().strip()
        existing_email = session.exec(select(User).where(User.email == email_value)).first()
        if existing_email:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already in use")
    else:
        email_value = None

    user = User(
        phone=phone_value,
        email=email_value,
        password_hash=get_password_hash(payload.password),
        first_name=payload.first_name,
        last_name=payload.last_name,
        avatar_url=payload.avatar_url,
        bio=payload.bio,
        role=payload.role if payload.role else UserRole.SERVICE_SEEKER,
    )
    session.add(user)
    session.commit()
    session.refresh(user)

    # Create address if provided
    if payload.address:
        address = Address(
            user_id=user.id,
            street=payload.address.street,
            city=payload.address.city,
            state=payload.address.state,
            postal_code=payload.address.postal_code,
            notes=payload.address.notes,
        )
        session.add(address)
        session.commit()

    # Create availability records if provided (for service providers)
    if payload.availability and user.role == UserRole.SERVICE_PROVIDER:
        for avail_data in payload.availability:
            availability = Availability(
                user_id=user.id,
                day_of_week=avail_data.day_of_week,
                start_time=avail_data.start_time,
                end_time=avail_data.end_time,
                is_available=avail_data.is_available,
            )
            session.add(availability)
        session.commit()

    session.refresh(user)
    return user


@router.post("/login")
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    session: Session = Depends(get_session),
):
    user = session.exec(select(User).where(User.phone == form_data.username.strip())).first()
    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect phone or password",
        )

    access_token_expires = timedelta(minutes=settings.access_token_expire_minutes)
    refresh_token_expires = timedelta(minutes=settings.refresh_token_expire_minutes)

    access_token = create_token(str(user.id), access_token_expires, "access")
    refresh_token = create_token(str(user.id), refresh_token_expires, "refresh")

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": UserRead.model_validate(user),
    }


@router.post("/refresh")
def refresh_token(refresh_token: str, session: Session = Depends(get_session)):
    payload = decode_token(refresh_token, expected_type="refresh")
    user = session.get(User, int(payload["sub"]))
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    access_token_expires = timedelta(minutes=settings.access_token_expire_minutes)
    new_access = create_token(str(user.id), access_token_expires, "access")
    return {"access_token": new_access, "token_type": "bearer"}

