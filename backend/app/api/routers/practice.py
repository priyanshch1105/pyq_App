from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_session
from app.models.models import User
from app.schemas.schemas import AttemptCreate, AttemptResult, PerformanceOut
from app.services.services import get_performance, submit_attempt

router = APIRouter(tags=["practice"])


@router.post("/attempt", response_model=AttemptResult)
async def attempt(
    payload: AttemptCreate,
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> AttemptResult:
    is_correct, correct_answer, explanation = await submit_attempt(session, user.id, payload)
    return AttemptResult(
        is_correct=is_correct,
        correct_answer=correct_answer,
        explanation=explanation,
    )


@router.get("/performance", response_model=PerformanceOut)
async def performance(
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> dict:
    return await get_performance(session, user.id)
