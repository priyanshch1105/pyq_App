from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_session
from app.models.models import User
from app.schemas.platform import ChatImageRequest, ChatRequest, ChatResponse
from app.services.platform import ai_tutor_reply

router = APIRouter(prefix="/chat", tags=["chatbot"])


@router.post("", response_model=ChatResponse)
async def chat(
    payload: ChatRequest,
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> ChatResponse:
    _ = session
    _ = user
    return await ai_tutor_reply(payload.message, payload.exam)


@router.post("/image", response_model=ChatResponse)
async def chat_image(
    payload: ChatImageRequest,
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> ChatResponse:
    _ = session
    _ = user
    message = payload.prompt or "Solve this question from image step by step"
    return await ai_tutor_reply(message, payload.exam)
