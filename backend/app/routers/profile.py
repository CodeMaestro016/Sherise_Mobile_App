from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Request
from sqlalchemy.orm import Session
from pathlib import Path
from uuid import uuid4
import mimetypes
import os
from ..database import get_db
from .. import models, schemas
from ..security import get_current_user

router = APIRouter(prefix="/profile", tags=["User Profile"])
UPLOAD_DIR = Path(__file__).resolve().parent.parent / "static" / "uploads" / "profile_pics"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
ALLOWED_TYPES = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}
MAX_SIZE = 2 * 1024 * 1024

def photo_url(request: Request, filename: str | None):
    if not filename:
        return None
    return str(request.base_url).rstrip("/") + f"/static/uploads/profile_pics/{filename}"

def ensure_profile(db: Session, user: models.User) -> models.Profile:
    profile = db.query(models.Profile).filter(models.Profile.user_id == user.id).first()
    if not profile:
        profile = models.Profile(user_id=user.id, full_name=user.name)
        db.add(profile)
        db.commit()
        db.refresh(profile)
    return profile

@router.get("", response_model=schemas.ProfileOut)
def get_profile(request: Request, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    profile = ensure_profile(db, current_user)
    data = schemas.ProfileOut.model_validate(profile)
    data.profile_photo = photo_url(request, profile.profile_photo)
    return data

@router.put("", response_model=schemas.ProfileOut)
def update_profile(payload: schemas.ProfileUpdate, request: Request, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    profile = ensure_profile(db, current_user)
    for key, value in payload.model_dump().items():
        setattr(profile, key, value.strip() if isinstance(value, str) else value)
    current_user.name = payload.full_name.strip()
    db.commit()
    db.refresh(profile)
    data = schemas.ProfileOut.model_validate(profile)
    data.profile_photo = photo_url(request, profile.profile_photo)
    return data

@router.post("/photo")
async def upload_profile_photo(request: Request, file: UploadFile = File(...), db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    extension = ALLOWED_TYPES.get(file.content_type)
    if not extension:
        guessed_type, _ = mimetypes.guess_type(file.filename or "")
        if guessed_type in ALLOWED_TYPES:
            extension = ALLOWED_TYPES[guessed_type]
    if not extension:
        raise HTTPException(status_code=400, detail="Only JPG, PNG, or WEBP images are allowed")
    content = await file.read()
    if len(content) == 0:
        raise HTTPException(status_code=400, detail="Empty image file")
    if len(content) > MAX_SIZE:
        raise HTTPException(status_code=400, detail="Profile photo must be less than 2MB")
    profile = ensure_profile(db, current_user)
    if profile.profile_photo:
        old = UPLOAD_DIR / profile.profile_photo
        if old.exists():
            old.unlink()
    filename = f"user_{current_user.id}_{uuid4().hex}{extension}"
    path = UPLOAD_DIR / filename
    path.write_bytes(content)
    profile.profile_photo = filename
    db.commit()
    return {"message": "Profile photo uploaded", "profile_photo": photo_url(request, filename)}

@router.delete("/photo")
def delete_profile_photo(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    profile = ensure_profile(db, current_user)
    if profile.profile_photo:
        path = UPLOAD_DIR / profile.profile_photo
        if path.exists():
            os.remove(path)
        profile.profile_photo = None
        db.commit()
    return {"message": "Profile photo removed"}
