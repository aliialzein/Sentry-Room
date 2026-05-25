from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.system import SystemSetting
from app.schemas.system import SystemSettingRead, SystemSettingUpsert


router = APIRouter()


@router.get("", response_model=list[SystemSettingRead])
def list_settings(db: Session = Depends(get_db)) -> list[SystemSetting]:
    statement = select(SystemSetting).order_by(SystemSetting.key.asc())
    return list(db.scalars(statement))


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
