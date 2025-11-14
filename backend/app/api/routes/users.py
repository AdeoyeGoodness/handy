from fastapi import APIRouter, Depends
from sqlmodel import Session, select

from ...models.user import User, UserRead
from ..deps import get_current_active_user, get_db

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserRead)
def read_current_user(current_user: User = Depends(get_current_active_user)) -> User:
    return current_user


@router.get("/", response_model=list[UserRead])
def list_providers(session: Session = Depends(get_db)) -> list[User]:
    result = session.exec(select(User).where(User.role == "SERVICE_PROVIDER"))
    return [UserRead.model_validate(user) for user in result.all()]

