from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.enums import SecurityMode
from app.models.system import SystemSetting
from app.schemas.system import SecurityModeRead, SecurityModeUpdate, SystemSettingRead, SystemSettingUpsert


router = APIRouter()

SECURITY_MODE_KEY = "security_mode"

SECURITY_MODE_DESCRIPTIONS = {
    SecurityMode.DISARMED: "Setup mode. Only emergency conditions should alert.",
    SecurityMode.WORKING_HOURS: "Normal daytime monitoring with reduced alert noise.",
    SecurityMode.LOCKED: "Room is closed. Person activity should be treated as suspicious.",
}


@router.get("", response_model=list[SystemSettingRead])
def list_settings(db: Session = Depends(get_db)) -> list[SystemSetting]:
    statement = select(SystemSetting).order_by(SystemSetting.key.asc())
    return list(db.scalars(statement))


@router.get("/security-mode", response_model=SecurityModeRead)
def get_security_mode(db: Session = Depends(get_db)) -> SecurityModeRead:
    mode = _current_security_mode(db)
    return SecurityModeRead(mode=mode, description=SECURITY_MODE_DESCRIPTIONS[mode])


@router.put("/security-mode", response_model=SecurityModeRead, status_code=status.HTTP_200_OK)
def update_security_mode(payload: SecurityModeUpdate, db: Session = Depends(get_db)) -> SecurityModeRead:
    setting = db.get(SystemSetting, SECURITY_MODE_KEY)
    value = {"mode": payload.mode.value}
    description = SECURITY_MODE_DESCRIPTIONS[payload.mode]

    if setting is None:
        setting = SystemSetting(
            key=SECURITY_MODE_KEY,
            value=value,
            description=description,
        )
        db.add(setting)
    else:
        setting.value = value
        setting.description = description

    db.commit()
    return SecurityModeRead(mode=payload.mode, description=description)


@router.put("/{key}", response_model=SystemSettingRead, status_code=status.HTTP_200_OK)
def upsert_setting(key: str, payload: SystemSettingUpsert, db: Session = Depends(get_db)) -> SystemSetting:
    setting = db.get(SystemSetting, key)
    if setting is None:
        setting = SystemSetting(key=key, value=payload.value, description=payload.description)
        db.add(setting)
    else:
        setting.value = payload.value
        setting.description = payload.description

    db.commit()
    db.refresh(setting)
    return setting


def _current_security_mode(db: Session) -> SecurityMode:
    setting = db.get(SystemSetting, SECURITY_MODE_KEY)
    if setting is None:
        return SecurityMode.WORKING_HOURS

    raw_mode = (setting.value or {}).get("mode")
    if raw_mode in {"deep_night", "lockdown"}:
        return SecurityMode.LOCKED
    try:
        return SecurityMode(raw_mode)
    except ValueError:
        return SecurityMode.WORKING_HOURS
