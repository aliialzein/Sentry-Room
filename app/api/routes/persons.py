from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.person import Person
from app.schemas.person import EnrollImageRequest, PersonCreate, PersonRead, PersonUpdate
from app.services.recognition import FaceRecognitionService
from app.services.storage import decode_base64_payload, save_bytes_file


router = APIRouter()


@router.post("", response_model=PersonRead, status_code=status.HTTP_201_CREATED)
def create_person(payload: PersonCreate, db: Session = Depends(get_db)) -> Person:
    person = Person(**payload.model_dump())
    db.add(person)
    db.commit()
    db.refresh(person)
    return person


@router.get("", response_model=list[PersonRead])
def list_persons(
    authorized: bool | None = None,
    db: Session = Depends(get_db),
) -> list[Person]:
    statement = select(Person).order_by(Person.created_at.desc())
    if authorized is not None:
        statement = statement.where(Person.is_authorized == authorized)
    return list(db.scalars(statement))


@router.get("/{person_id}", response_model=PersonRead)
def get_person(person_id: int, db: Session = Depends(get_db)) -> Person:
    person = db.get(Person, person_id)
    if person is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Person not found")
    return person


@router.patch("/{person_id}", response_model=PersonRead)
def update_person(person_id: int, payload: PersonUpdate, db: Session = Depends(get_db)) -> Person:
    person = db.get(Person, person_id)
    if person is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Person not found")

    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(person, key, value)

    db.commit()
    db.refresh(person)
    return person


@router.post("/enroll-from-image", response_model=PersonRead, status_code=status.HTTP_201_CREATED)
def enroll_from_image(payload: EnrollImageRequest, db: Session = Depends(get_db)) -> Person:
    image_bytes = decode_base64_payload(payload.image_base64)
    recognizer = FaceRecognitionService()

    try:
        encoding = recognizer.encoding_from_image(image_bytes)
    except RuntimeError as exc:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    image_path = save_bytes_file(
        image_bytes,
        subdir="enrollments",
        filename_prefix=payload.full_name.replace(" ", "_").lower(),
    )
    person = Person(
        full_name=payload.full_name,
        role=payload.role,
        is_authorized=payload.is_authorized,
        face_encoding=encoding,
        image_path=image_path,
        notes=payload.notes,
    )
    db.add(person)
    db.commit()
    db.refresh(person)
    return person
