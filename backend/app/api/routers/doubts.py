from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_session
from app.models.models import User
from app.schemas.platform import DoubtCreate, DoubtDetailOut, DoubtOut, DoubtResponseCreate, DoubtResponseOut, DoubtUpdateStatus
from app.services.platform import add_doubt_response, create_doubt, get_doubt_detail, list_user_doubts, mark_doubt_status, upvote_response

router = APIRouter(prefix="/doubt", tags=["doubts"])


@router.post("", response_model=DoubtOut)
async def post_doubt(
    payload: DoubtCreate,
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> DoubtOut:
    return await create_doubt(session, user.id, payload)


@router.get("/{doubt_id}", response_model=DoubtDetailOut)
async def get_doubt(
    doubt_id: UUID,
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> DoubtDetailOut:
    doubt, responses = await get_doubt_detail(session, doubt_id, user.id)
    return DoubtDetailOut(
        id=doubt.id,
        user_id=doubt.user_id,
        subject=doubt.subject,
        chapter=doubt.chapter,
        question_type=doubt.question_type,
        question_text=doubt.question_text,
        image_url=doubt.image_url,
        status=doubt.status,
        created_at=doubt.created_at,
        responses=responses,
    )


@router.get("/user/me", response_model=list[DoubtOut])
async def my_doubts(
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> list[DoubtOut]:
    return await list_user_doubts(session, user.id)


@router.post("/{doubt_id}/response", response_model=DoubtResponseOut)
async def respond_to_doubt(
    doubt_id: UUID,
    payload: DoubtResponseCreate,
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> DoubtResponseOut:
    responder_id = user.id if payload.responder_type != "ai" else None
    return await add_doubt_response(session, doubt_id, responder_id, payload)


@router.patch("/{doubt_id}/status", response_model=DoubtOut)
async def update_doubt_status(
    doubt_id: UUID,
    payload: DoubtUpdateStatus,
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> DoubtOut:
    return await mark_doubt_status(session, doubt_id, payload.status, user.id)


@router.post("/response/{response_id}/helpful", response_model=DoubtResponseOut)
async def mark_helpful(
    response_id: UUID,
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> DoubtResponseOut:
    _ = user
    return await upvote_response(session, response_id)
