from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_session
from app.models.models import User
from app.schemas.platform import PerformanceAnalyticsOut
from app.services.platform import performance_analytics

router = APIRouter(prefix="/analytics", tags=["analytics"])


@router.get("/overview", response_model=PerformanceAnalyticsOut)
async def analytics_overview(
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> dict:
    return await performance_analytics(session, user.id)
