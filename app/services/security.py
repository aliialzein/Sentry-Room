import bcrypt
from datetime import datetime, timedelta

import jwt
from jwt import PyJWTError

from app.core.config import get_settings


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, password_hash: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8"))


def create_access_token(user_id: int) -> str:
    settings = get_settings()
    now = datetime.utcnow()
    payload = {
        "sub": str(user_id),
        "exp": now + timedelta(minutes=settings.access_token_expire_minutes),
        "iat": now,
    }
    return jwt.encode(payload, settings.secret_key, algorithm="HS256")


def decode_access_token(token: str) -> dict[str, str]:
    settings = get_settings()
    try:
        decoded = jwt.decode(token, settings.secret_key, algorithms=["HS256"])
    except PyJWTError as exc:
        raise ValueError("Invalid or expired authentication token.") from exc

    return {str(key): str(value) for key, value in decoded.items()}
