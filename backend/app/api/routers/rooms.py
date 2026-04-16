import asyncio
import json
from collections import defaultdict
from uuid import UUID

from fastapi import APIRouter, Depends, Query, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.config import settings
from app.db.session import AsyncSessionLocal, get_session
from app.models.models import User
from app.schemas.platform import RoomMessageCreate, RoomMessageOut, StudyRoomCreate, StudyRoomOut
from app.services.platform import create_room, list_room_messages, list_rooms, save_room_message

try:
    from redis.asyncio import Redis
except Exception:  # pragma: no cover - optional dependency import fallback
    Redis = None

router = APIRouter(prefix="/rooms", tags=["study-rooms"])


class RoomConnectionManager:
    def __init__(self) -> None:
        self.active_connections: dict[str, set[WebSocket]] = defaultdict(set)

    async def connect(self, room_id: str, websocket: WebSocket) -> None:
        await websocket.accept()
        self.active_connections[room_id].add(websocket)

    def disconnect(self, room_id: str, websocket: WebSocket) -> None:
        if room_id in self.active_connections:
            self.active_connections[room_id].discard(websocket)
            if not self.active_connections[room_id]:
                self.active_connections.pop(room_id, None)

    async def broadcast(self, room_id: str, payload: dict) -> None:
        for connection in list(self.active_connections.get(room_id, set())):
            await connection.send_json(payload)


class RedisRoomBus:
    def __init__(self) -> None:
        self.enabled = bool(settings.redis_url and Redis is not None)
        self.redis = Redis.from_url(settings.redis_url, decode_responses=True) if self.enabled else None

    async def publish(self, room_id: str, payload: dict) -> bool:
        if not self.enabled or not self.redis:
            return False
        await self.redis.publish(f"room:{room_id}", json.dumps(payload))
        return True

    async def subscribe_forward(self, room_id: str, websocket: WebSocket) -> None:
        if not self.enabled or not self.redis:
            return
        pubsub = self.redis.pubsub()
        await pubsub.subscribe(f"room:{room_id}")
        try:
            async for event in pubsub.listen():
                if event.get("type") != "message":
                    continue
                raw = event.get("data")
                if not raw:
                    continue
                await websocket.send_json(json.loads(raw))
        finally:
            await pubsub.unsubscribe(f"room:{room_id}")
            await pubsub.close()


manager = RoomConnectionManager()
room_bus = RedisRoomBus()


async def publish_room_event(room_id: str, payload: dict) -> None:
    pushed = await room_bus.publish(room_id, payload)
    if not pushed:
        await manager.broadcast(room_id, payload)


@router.post("", response_model=StudyRoomOut)
async def create_study_room(
    payload: StudyRoomCreate,
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> StudyRoomOut:
    return await create_room(session, payload, user.id)


@router.get("", response_model=list[StudyRoomOut])
async def get_study_rooms(
    exam: str | None = Query(default=None),
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> list[StudyRoomOut]:
    _ = user
    return await list_rooms(session, exam=exam)


@router.get("/{room_id}/messages", response_model=list[RoomMessageOut])
async def get_messages(
    room_id: UUID,
    limit: int = Query(default=100, ge=1, le=500),
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> list[RoomMessageOut]:
    _ = user
    return await list_room_messages(session, room_id, limit)


@router.post("/{room_id}/message", response_model=RoomMessageOut)
async def post_message(
    room_id: UUID,
    payload: RoomMessageCreate,
    session: AsyncSession = Depends(get_session),
    user: User = Depends(get_current_user),
) -> RoomMessageOut:
    message = await save_room_message(session, room_id, user.id, payload.message)
    event = {
        "event": "receive_message",
        "room_id": str(room_id),
        "user_id": str(user.id),
        "message": message.message,
        "timestamp": message.timestamp.isoformat(),
    }
    await publish_room_event(str(room_id), event)
    return message


@router.websocket("/ws/{room_id}")
async def room_ws(websocket: WebSocket, room_id: str, user_id: str = Query(default="anonymous")) -> None:
    await manager.connect(room_id, websocket)
    forward_task = None
    if room_bus.enabled:
        forward_task = asyncio.create_task(room_bus.subscribe_forward(room_id, websocket))

    try:
        await publish_room_event(room_id, {"event": "user_joined", "room_id": room_id, "user_id": user_id})

        while True:
            data = await websocket.receive_json()
            event = data.get("event")
            if event == "send_message":
                text = str(data.get("message", "")).strip()
                if not text:
                    continue

                # Persist best-effort; websocket still works if persistence fails.
                try:
                    room_uuid = UUID(room_id)
                    sender_uuid = UUID(user_id)
                    async with AsyncSessionLocal() as session:
                        await save_room_message(session, room_uuid, sender_uuid, text)
                except Exception:
                    pass

                await publish_room_event(
                    room_id,
                    {
                        "event": "receive_message",
                        "room_id": room_id,
                        "user_id": user_id,
                        "message": text,
                    },
                )
    except WebSocketDisconnect:
        manager.disconnect(room_id, websocket)
        await publish_room_event(room_id, {"event": "user_left", "room_id": room_id, "user_id": user_id})
    finally:
        if forward_task:
            forward_task.cancel()
