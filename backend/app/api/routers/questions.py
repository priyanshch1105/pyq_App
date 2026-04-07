from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_session
from app.models.models import Question, User
from app.schemas.schemas import QuestionOut
from app.services.services import fetch_questions

router = APIRouter(prefix="/questions", tags=["questions"])


@router.get("", response_model=list[QuestionOut])
async def list_questions(
    exam: str | None = None,
    subject: str | None = None,
    topic: str | None = None,
    year: int | None = Query(default=None, ge=2010),
    limit: int = Query(default=20, le=100),
    offset: int = Query(default=0, ge=0),
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> list[Question]:
    return await fetch_questions(session, user.is_premium, exam, subject, topic, year, limit, offset)


@router.get("/{question_id}", response_model=QuestionOut)
async def get_question(
    question_id: UUID,
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> Question:
    row = await session.scalar(select(Question).where(Question.id == question_id))
    if not row:
        raise HTTPException(status_code=404, detail="Question not found")
    return row
