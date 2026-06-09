from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.person import Person
from app.schemas.person import EnrollCameraRequest, EnrollImageRequest, PersonCreate, PersonRead, PersonUpdate
from app.services.face_duplicates import find_existing_face_match
from app.services.face_index import face_index
from app.services.isolated_face_recognition import encoding_from_image_isolated
from app.services.pi_camera_stream import pi_camera_stream
from app.services.storage import decode_base64_payload, save_bytes_file


router = APIRouter()


@router.post("", response_model=PersonRead, status_code=status.HTTP_201_CREATED)
def create_person(payload: PersonCreate, db: Session = Depends(get_db)) -> Person:
    data = payload.model_dump()
    encoding = data.pop("face_encoding", None)
    person = Person(**data)
    db.add(person)
    db.flush()
    if encoding is not None:
        duplicate = find_existing_face_match(db, encoding, exclude_person_id=person.id)
        if duplicate is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"This face is already enrolled as {duplicate.name} (person {duplicate.person_id}).",
            )
        face_index.add_person_encoding(person.id, encoding)
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

    data = payload.model_dump(exclude_unset=True)
    encoding = data.pop("face_encoding", None)
    for key, value in data.items():
        setattr(person, key, value)

    if encoding is not None:
        duplicate = find_existing_face_match(db, encoding, exclude_person_id=person.id)
        if duplicate is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"This face is already enrolled as {duplicate.name} (person {duplicate.person_id}).",
            )
        face_index.replace_person_encodings(person.id, [encoding])

    db.commit()
    db.refresh(person)
    return person


@router.post("/enroll-from-image", response_model=PersonRead, status_code=status.HTTP_201_CREATED)
def enroll_from_image(payload: EnrollImageRequest, db: Session = Depends(get_db)) -> Person:
    image_bytes = decode_base64_payload(payload.image_base64)
    return _enroll_person_from_image_bytes(
        db=db,
        image_bytes=image_bytes,
        full_name=payload.full_name,
        role=payload.role,
        is_authorized=payload.is_authorized,
        notes=payload.notes,
    )


@router.post("/enroll-from-camera", response_model=PersonRead, status_code=status.HTTP_201_CREATED)
def enroll_from_camera(payload: EnrollCameraRequest, db: Session = Depends(get_db)) -> Person:
    frame = pi_camera_stream.wait_for_frame(timeout=2.0)
    if frame is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="No Pi camera frame has been received yet.",
        )

    return _enroll_person_from_image_bytes(
        db=db,
        image_bytes=frame,
        full_name=payload.full_name,
        role=payload.role,
        is_authorized=payload.is_authorized,
        notes=payload.notes,
    )


def _enroll_person_from_image_bytes(
    db: Session,
    image_bytes: bytes,
    full_name: str,
    role: str | None,
    is_authorized: bool,
    notes: str | None,
) -> Person:
    try:
        encoding = encoding_from_image_isolated(image_bytes)
    except RuntimeError as exc:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    duplicate = find_existing_face_match(db, encoding)
    if duplicate is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"This face is already enrolled as {duplicate.name} (person {duplicate.person_id}).",
        )

    image_path = save_bytes_file(
        image_bytes,
        subdir="enrollments",
        filename_prefix=full_name.replace(" ", "_").lower(),
    )
    person = Person(
        full_name=full_name,
        role=role,
        is_authorized=is_authorized,
        face_encoding=None,
        image_path=image_path,
        notes=notes,
    )
    db.add(person)
    db.flush()
    face_index.add_person_encoding(person.id, encoding)
    db.commit()
    db.refresh(person)
    return person
