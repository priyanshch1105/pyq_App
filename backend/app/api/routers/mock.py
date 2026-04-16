from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_session
from app.models.models import User
from app.schemas.platform import PredictedTestOut
from app.services.platform import predicted_mock_for_user

router = APIRouter(prefix="/mock", tags=["mock"])


@router.get("/predicted", response_model=PredictedTestOut)
async def predicted_mock(
    exam: str = Query(default="JEE_MAIN"),
    total_questions: int = Query(default=30, ge=10, le=200),
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> dict:
    return await predicted_mock_for_user(session, user.id, exam=exam, total_questions=total_questions)
