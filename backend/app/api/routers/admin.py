from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_session
from app.models.models import Announcement, Question, User
from app.schemas.schemas import AdminStatsOut, AnnouncementCreate, AnnouncementOut, QuestionCreate

router = APIRouter(prefix="/admin", tags=["admin"])

def require_admin(user: User):
    if not user.is_admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin privileges required")

@router.get("/stats", response_model=AdminStatsOut)
async def get_admin_stats(
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user)
) -> AdminStatsOut:
    require_admin(current_user)
    total_users = await session.scalar(select(func.count(User.id)))
    premium_users = await session.scalar(select(func.count(User.id)).where(User.is_premium == True))
    total_questions = await session.scalar(select(func.count(Question.id)))
    
    return AdminStatsOut(
        total_users=total_users or 0,
        premium_users=premium_users or 0,
        total_questions=total_questions or 0,
    )


@router.get("/announcements", response_model=list[AnnouncementOut])
async def list_announcements(
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user)
) -> list[AnnouncementOut]:
    require_admin(current_user)
    rows = await session.scalars(
        select(Announcement).order_by(Announcement.created_at.desc())
    )
    return list(rows)

@router.post("/questions", response_model=dict)
async def create_question(
    payload: QuestionCreate,
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    require_admin(current_user)
    question = Question(
        exam=payload.exam,
        subject=payload.subject,
        topic=payload.topic,
        year=payload.year,
        difficulty=payload.difficulty,
        question=payload.question,
        options=payload.options,
        correct_answer=payload.correct_answer,
        explanation=payload.explanation,
    )
    session.add(question)
    await session.commit()
    return {"message": "Question added successfully"}

@router.post("/announcements", response_model=AnnouncementOut)
async def create_announcement(
    payload: AnnouncementCreate,
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user)
) -> AnnouncementOut:
    require_admin(current_user)
    announcement = Announcement(
        title=payload.title,
        content=payload.content,
        is_premium_only=payload.is_premium_only,
    )
    session.add(announcement)
    await session.commit()
    await session.refresh(announcement)
    return announcement
