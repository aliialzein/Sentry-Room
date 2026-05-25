from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.enums import UserRole
from app.models.user import User
from app.schemas.user import AuthResponse, UserLogin, UserRegister
from app.services.security import hash_password, verify_password


router = APIRouter()


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def register_user(payload: UserRegister, db: Session = Depends(get_db)) -> AuthResponse:
    existing_user = db.scalar(
        select(User).where(
            or_(
                User.username == payload.username,
                User.email == payload.email,
            )
        )
    )
    if existing_user is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Username or email already exists.",
        )

    user = User(
        username=payload.username,
        email=payload.email,
        full_name=payload.full_name,
        password_hash=hash_password(payload.password),
        role=UserRole.ADMIN if _is_first_user(db) else UserRole.VIEWER,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    return AuthResponse(user=user, message="User registered successfully.")


@router.post("/login", response_model=AuthResponse)
def login_user(payload: UserLogin, db: Session = Depends(get_db)) -> AuthResponse:
    user = db.scalar(
        select(User).where(
            or_(
                User.username == payload.identifier,
                User.email == payload.identifier,
            )
        )
    )
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials.")

    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="User account is disabled.")

    return AuthResponse(user=user, message="Login successful.")


def _is_first_user(db: Session) -> bool:
    return (db.scalar(select(func.count()).select_from(User)) or 0) == 0
