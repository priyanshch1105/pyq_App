from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_session
from app.models.models import User
from app.schemas.schemas import RecommendationOut
from app.services.services import get_recommendations

router = APIRouter(prefix="/recommendations", tags=["recommendations"])


@router.get("", response_model=list[RecommendationOut])
async def recommendations(
    limit: int = Query(default=10, le=50),
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> list[dict]:
    if not user.is_premium:
        raise HTTPException(status_code=403, detail="Premium subscription required")
    return await get_recommendations(session, user.id, limit=limit)
