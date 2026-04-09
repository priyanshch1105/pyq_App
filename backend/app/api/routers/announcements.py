from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_session
from app.models.models import Announcement, User
from app.schemas.schemas import AnnouncementOut

router = APIRouter(prefix="/announcements", tags=["announcements"])

@router.get("", response_model=list[AnnouncementOut])
async def get_announcements(
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user)
) -> list[AnnouncementOut]:
    query = select(Announcement).order_by(Announcement.created_at.desc())
    if not current_user.is_admin and not current_user.is_premium:
        query = query.where(Announcement.is_premium_only == False)
    
    rows = await session.scalars(query)
    return list(rows)
