from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, WebSocket, WebSocketDisconnect
from jose import JWTError, jwt
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
import json
from uuid import UUID

from app.api.deps import get_current_user
from app.core.config import settings
from app.db.session import get_session
from app.models.models import Announcement, Question, User
from app.schemas.schemas import (
    ActiveUserSampleOut,
    AdminRealtimeSnapshotOut,
    AdminStatsOut,
    AnnouncementCreate,
    AnnouncementOut,
    BulkQuestionUploadResponse,
    QuestionCreate,
)
from app.services.admin_realtime import admin_realtime_tracker
from app.api.routers.rooms import manager as room_manager

router = APIRouter(prefix="/admin", tags=["admin"])

def require_admin(user: User):
    if not user.is_admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin privileges required")


async def _build_snapshot() -> AdminRealtimeSnapshotOut:
    tracked_users = [
        ActiveUserSampleOut(**row)
        for row in await admin_realtime_tracker.active_user_samples(limit=8)
    ]
    return AdminRealtimeSnapshotOut(
        active_users=await admin_realtime_tracker.active_user_count(),
        active_rooms=len(room_manager.active_connections),
        tracked_users=tracked_users,
    )


async def _dashboard_payload(event: str = "dashboard_snapshot") -> dict:
    snapshot = await _build_snapshot()
    return {
        "event": event,
        "active_users": snapshot.active_users,
        "active_rooms": snapshot.active_rooms,
        "tracked_users": [
            {
                "user_id": str(user.user_id),
                "email": user.email,
                "last_seen": user.last_seen.isoformat(),
            }
            for user in snapshot.tracked_users
        ],
    }


async def authenticate_admin_ws(websocket: WebSocket) -> User:
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=4401)
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing token")

    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        user_id = payload.get("sub")
        if not user_id:
            raise ValueError("Missing subject")
    except (JWTError, ValueError):
        await websocket.close(code=4401)
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    async for session in get_session():
        user = await session.scalar(select(User).where(User.id == UUID(user_id)))
        if not user or not user.is_admin:
            await websocket.close(code=4403)
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin privileges required")
        return user

    await websocket.close(code=1011)
    raise HTTPException(status_code=500, detail="Unable to create session")

@router.get("/stats", response_model=AdminStatsOut)
async def get_admin_stats(
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user)
) -> AdminStatsOut:
    require_admin(current_user)
    total_users = await session.scalar(select(func.count(User.id)))
    premium_users = await session.scalar(select(func.count(User.id)).where(User.is_premium == True))
    total_questions = await session.scalar(select(func.count(Question.id)))
    total_announcements = await session.scalar(select(func.count(Announcement.id)))
    
    return AdminStatsOut(
        total_users=total_users or 0,
        premium_users=premium_users or 0,
        total_questions=total_questions or 0,
        active_users=await admin_realtime_tracker.active_user_count(),
        active_rooms=len(room_manager.active_connections),
        total_announcements=total_announcements or 0,
    )


@router.get("/realtime", response_model=AdminRealtimeSnapshotOut)
async def get_realtime_snapshot(
    current_user: User = Depends(get_current_user),
) -> AdminRealtimeSnapshotOut:
    require_admin(current_user)
    return await _build_snapshot()


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
    await admin_realtime_tracker.broadcast_announcement(
        {
            "event": "announcement_created",
            "announcement": {
                "id": str(announcement.id),
                "title": announcement.title,
                "content": announcement.content,
                "is_premium_only": announcement.is_premium_only,
                "created_at": announcement.created_at.isoformat(),
            },
        }
    )
    await admin_realtime_tracker.broadcast_dashboard(await _dashboard_payload())
    return announcement


@router.post("/bulk-questions", response_model=BulkQuestionUploadResponse)
async def bulk_upload_questions(
    file: UploadFile = File(...),
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user)
) -> BulkQuestionUploadResponse:
    """Upload multiple questions from a JSON file"""
    require_admin(current_user)
    
    if not file.filename.endswith('.json'):
        raise HTTPException(status_code=400, detail="Only JSON files are supported")
    
    try:
        content = await file.read()
        questions_data = json.loads(content.decode('utf-8'))
        
        if not isinstance(questions_data, list):
            raise HTTPException(status_code=400, detail="JSON must be an array of question objects")
        
        inserted = 0
        skipped = 0
        failed = 0
        errors = []
        
        for idx, q in enumerate(questions_data):
            try:
                # Validate required fields
                required = ['exam', 'subject', 'topic', 'year', 'question', 'correct_answer', 'options']
                for field in required:
                    if field not in q:
                        raise ValueError(f"Missing field: {field}")
                
                # Check for duplicates
                existing = await session.scalar(
                    select(Question).where(
                        (Question.exam == q['exam']) &
                        (Question.year == int(q['year'])) &
                        (Question.question == q['question'])
                    )
                )
                
                if existing:
                    skipped += 1
                    continue
                
                # Create question
                question = Question(
                    exam=q['exam'],
                    subject=q.get('subject', 'Unknown'),
                    topic=q.get('topic', 'Unknown'),
                    year=int(q['year']),
                    difficulty=int(q.get('difficulty', 1)),
                    question=q['question'],
                    options=q.get('options', {}),
                    correct_answer=str(q['correct_answer']).upper(),
                    explanation=q.get('explanation', ''),
                    weightage=float(q.get('weightage', 1.0)),
                )
                session.add(question)
                inserted += 1
                
            except Exception as e:
                failed += 1
                errors.append({
                    "row": idx + 1,
                    "error": str(e)
                })
        
        await session.commit()
        
        return BulkQuestionUploadResponse(
            total_processed=len(questions_data),
            inserted=inserted,
            skipped=skipped,
            failed=failed,
            errors=errors
        )
        
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON format")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing file: {str(e)}")


@router.websocket("/ws/dashboard")
async def admin_dashboard_ws(websocket: WebSocket) -> None:
    user = await authenticate_admin_ws(websocket)
    await admin_realtime_tracker.touch_user(user.id, user.email)
    await admin_realtime_tracker.register_dashboard(websocket)
    await admin_realtime_tracker.broadcast_dashboard(await _dashboard_payload("admin_connected"))
    try:
        await websocket.send_json(await _dashboard_payload())
        while True:
            message = await websocket.receive_json()
            if message.get("event") == "ping":
                await admin_realtime_tracker.touch_user(user.id, user.email)
                await websocket.send_json(await _dashboard_payload("pong"))
    except WebSocketDisconnect:
        admin_realtime_tracker.unregister_dashboard(websocket)
        await admin_realtime_tracker.broadcast_dashboard(await _dashboard_payload("admin_disconnected"))
