from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

from app.api.deps import get_current_user
from app.core.config import settings
from app.db.session import get_session
from app.models.models import Announcement, User
from app.schemas.schemas import AnnouncementOut
from app.services.admin_realtime import admin_realtime_tracker

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


@router.websocket("/ws")
async def announcements_ws(websocket: WebSocket) -> None:
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=4401)
        return

    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        user_id = payload.get("sub")
        if not user_id:
            raise ValueError("Missing subject")
    except (JWTError, ValueError):
        await websocket.close(code=4401)
        return

    async for session in get_session():
        user = await session.scalar(select(User).where(User.id == UUID(user_id)))
        if not user:
            await websocket.close(code=4401)
            return

        await admin_realtime_tracker.touch_user(user.id, user.email)
        await admin_realtime_tracker.register_announcement(websocket)
        try:
            await websocket.send_json({"event": "connected"})
            while True:
                payload = await websocket.receive_json()
                if payload.get("event") == "ping":
                    await admin_realtime_tracker.touch_user(user.id, user.email)
                    await websocket.send_json({"event": "pong"})
        except WebSocketDisconnect:
            admin_realtime_tracker.unregister_announcement(websocket)
            return
