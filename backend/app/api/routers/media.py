import hashlib
import time
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.config import settings
from app.db.session import get_session
from app.models.models import User
from app.schemas.platform import SignedUploadRequest, SignedUploadResponse

router = APIRouter(prefix="/media", tags=["media"])


@router.post("/sign-upload", response_model=SignedUploadResponse)
async def sign_upload(
    payload: SignedUploadRequest,
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> SignedUploadResponse:
    _ = session
    _ = user

    provider = payload.provider.lower()
    if provider != "cloudinary":
        raise HTTPException(status_code=400, detail="Only cloudinary provider is currently enabled")

    if not settings.cloudinary_cloud_name or not settings.cloudinary_api_key or not settings.cloudinary_api_secret:
        raise HTTPException(status_code=500, detail="Cloudinary credentials not configured")

    timestamp = int(time.time())
    public_id = f"{payload.folder}/{uuid4().hex}_{payload.filename.rsplit('.', 1)[0]}"

    to_sign = f"folder={payload.folder}&public_id={public_id}&timestamp={timestamp}{settings.cloudinary_api_secret}"
    signature = hashlib.sha1(to_sign.encode("utf-8")).hexdigest()

    return SignedUploadResponse(
        provider="cloudinary",
        upload_url=f"https://api.cloudinary.com/v1_1/{settings.cloudinary_cloud_name}/image/upload",
        public_id=public_id,
        timestamp=timestamp,
        api_key=settings.cloudinary_api_key,
        signature=signature,
        folder=payload.folder,
    )
