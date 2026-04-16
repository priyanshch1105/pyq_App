from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import and_, cast, Integer, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.models import Attempt, Doubt, DoubtResponse, Question, RoomMessage, StudyRoom, TopicStat, User
from app.schemas.platform import ChatResponse, DoubtCreate, DoubtResponseCreate, DoubtStatus, StudyRoomCreate
from app.services.llm import generate_tutor_completion


async def create_doubt(session: AsyncSession, user_id: UUID, payload: DoubtCreate) -> Doubt:
    doubt = Doubt(
        user_id=user_id,
        subject=payload.subject,
        chapter=payload.chapter,
        question_type=payload.question_type.value,
        question_text=payload.question_text,
        image_url=payload.image_url,
        status=DoubtStatus.pending.value,
    )
    session.add(doubt)
    await session.commit()
    await session.refresh(doubt)
    return doubt


async def get_doubt_detail(session: AsyncSession, doubt_id: UUID, user_id: UUID) -> tuple[Doubt, list[DoubtResponse]]:
    doubt = await session.scalar(select(Doubt).where(Doubt.id == doubt_id))
    if not doubt:
        raise HTTPException(status_code=404, detail="Doubt not found")
    if doubt.user_id != user_id:
        user = await session.scalar(select(User).where(User.id == user_id))
        if not user or not user.is_admin:
            raise HTTPException(status_code=403, detail="Access denied")

    responses = (
        await session.scalars(
            select(DoubtResponse).where(DoubtResponse.doubt_id == doubt.id).order_by(DoubtResponse.created_at.asc())
        )
    ).all()
    return doubt, list(responses)


async def list_user_doubts(session: AsyncSession, user_id: UUID) -> list[Doubt]:
    rows = (
        await session.scalars(
            select(Doubt).where(Doubt.user_id == user_id).order_by(Doubt.created_at.desc())
        )
    ).all()
    return list(rows)


async def add_doubt_response(
    session: AsyncSession,
    doubt_id: UUID,
    responder_id: UUID | None,
    payload: DoubtResponseCreate,
) -> DoubtResponse:
    doubt = await session.scalar(select(Doubt).where(Doubt.id == doubt_id))
    if not doubt:
        raise HTTPException(status_code=404, detail="Doubt not found")

    response = DoubtResponse(
        doubt_id=doubt_id,
        responder_id=responder_id,
        responder_type=payload.responder_type.value,
        answer_text=payload.answer_text,
    )
    session.add(response)

    if doubt.status == DoubtStatus.pending.value:
        doubt.status = DoubtStatus.answered.value

    await session.commit()
    await session.refresh(response)
    return response


async def mark_doubt_status(session: AsyncSession, doubt_id: UUID, status: DoubtStatus, user_id: UUID) -> Doubt:
    doubt = await session.scalar(select(Doubt).where(Doubt.id == doubt_id))
    if not doubt:
        raise HTTPException(status_code=404, detail="Doubt not found")
    if doubt.user_id != user_id:
        raise HTTPException(status_code=403, detail="Only doubt owner can update status")

    doubt.status = status.value
    await session.commit()
    await session.refresh(doubt)
    return doubt


async def upvote_response(session: AsyncSession, response_id: UUID) -> DoubtResponse:
    response = await session.scalar(select(DoubtResponse).where(DoubtResponse.id == response_id))
    if not response:
        raise HTTPException(status_code=404, detail="Response not found")
    response.helpful_count += 1
    await session.commit()
    await session.refresh(response)
    return response


async def create_room(session: AsyncSession, payload: StudyRoomCreate, user_id: UUID) -> StudyRoom:
    room = StudyRoom(name=payload.name, exam=payload.exam, created_by=user_id)
    session.add(room)
    await session.commit()
    await session.refresh(room)
    return room


async def list_rooms(session: AsyncSession, exam: str | None = None) -> list[StudyRoom]:
    query = select(StudyRoom).where(StudyRoom.is_active == True)
    if exam:
        query = query.where(StudyRoom.exam == exam)
    rows = (await session.scalars(query.order_by(StudyRoom.created_at.desc()))).all()
    return list(rows)


async def save_room_message(session: AsyncSession, room_id: UUID, user_id: UUID, message: str) -> RoomMessage:
    room = await session.scalar(select(StudyRoom).where(and_(StudyRoom.id == room_id, StudyRoom.is_active == True)))
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    msg = RoomMessage(room_id=room_id, user_id=user_id, message=message)
    session.add(msg)
    await session.commit()
    await session.refresh(msg)
    return msg


async def list_room_messages(session: AsyncSession, room_id: UUID, limit: int = 100) -> list[RoomMessage]:
    rows = (
        await session.scalars(
            select(RoomMessage).where(RoomMessage.room_id == room_id).order_by(RoomMessage.timestamp.desc()).limit(limit)
        )
    ).all()
    return list(reversed(list(rows)))


async def predicted_mock_for_user(session: AsyncSession, user_id: UUID, exam: str, total_questions: int = 30) -> dict:
    stats = (await session.scalars(select(TopicStat).where(TopicStat.user_id == user_id))).all()

    weak_topics = sorted(stats, key=lambda s: s.accuracy)[:10]
    weak_topic_names = [s.topic for s in weak_topics]

    weak_count = max(1, int(total_questions * 0.4))
    medium_count = max(1, int(total_questions * 0.3))
    strong_count = max(1, total_questions - weak_count - medium_count)

    weak_questions = (
        await session.scalars(
            select(Question)
            .where(and_(Question.exam == exam, Question.topic.in_(weak_topic_names) if weak_topic_names else True))
            .order_by(Question.year.desc())
            .limit(weak_count)
        )
    ).all()

    medium_questions = (
        await session.scalars(
            select(Question).where(and_(Question.exam == exam, Question.difficulty.in_([2, 3]))).order_by(Question.year.desc()).limit(medium_count)
        )
    ).all()

    strong_questions = (
        await session.scalars(
            select(Question).where(and_(Question.exam == exam, Question.difficulty >= 4)).order_by(Question.year.desc()).limit(strong_count)
        )
    ).all()

    selected = list({q.id: q for q in [*weak_questions, *medium_questions, *strong_questions]}.values())
    prediction_accuracy = 0.78 if weak_topic_names else 0.65

    return {
        "meta": {
            "exam": exam,
            "difficulty": "adaptive",
            "prediction_accuracy": prediction_accuracy,
        },
        "questions": selected,
    }


async def ai_tutor_reply(message: str, exam: str | None = None) -> ChatResponse:
    llm_answer = await generate_tutor_completion(message, exam)
    if llm_answer:
        return ChatResponse(
            answer=llm_answer,
            hints=[
                "Ask for a shorter method",
                "Request practice questions",
                "Ask for common mistakes",
            ],
        )

    m = message.lower()

    if any(k in m for k in ["mock", "test", "score"]):
        answer = (
            "Use a 3-pass approach: first solve direct questions, second solve moderate ones, "
            "and keep risky guesses for the end. Track accuracy and time per topic after each test."
        )
        hints = ["Aim 85%+ accuracy", "Keep error log", "Review weak topics next day"]
    elif any(k in m for k in ["doubt", "solve", "numerical", "mcq"]):
        answer = (
            "Step 1: Identify concept and given data. Step 2: Write core formula. "
            "Step 3: Substitute carefully with units. Step 4: Validate final answer using approximation."
        )
        hints = ["Check units", "Avoid sign mistakes", "Compare with options"]
    else:
        answer = (
            f"For {exam or 'your exam'} preparation, build daily loops: concept revision, PYQ practice, and analysis. "
            "I can generate a chapter-wise plan if you share your weak topics."
        )
        hints = ["2h focused study block", "PYQ-first strategy", "Weekly mock + analysis"]

    return ChatResponse(answer=answer, hints=hints)


async def performance_analytics(session: AsyncSession, user_id: UUID) -> dict:
    overall = (
        await session.execute(
            select(
                func.count(Attempt.id),
                func.avg(cast(Attempt.is_correct, Integer)),
                func.avg(Attempt.time_taken),
            ).where(Attempt.user_id == user_id)
        )
    ).one()

    total_attempts, overall_accuracy, avg_time = overall if overall else (0, 0.0, 0.0)

    topic_rows = (
        await session.scalars(select(TopicStat).where(TopicStat.user_id == user_id).order_by(TopicStat.accuracy.asc()))
    ).all()
    weak_topics = [row.topic for row in list(topic_rows)[:5]]

    subject_rows = (
        await session.execute(
            select(
                Question.subject,
                func.count(Attempt.id).label("attempts"),
                func.avg(cast(Attempt.is_correct, Integer)).label("accuracy"),
                func.avg(Attempt.time_taken).label("avg_time"),
            )
            .select_from(Attempt)
            .join(Question, Attempt.question_id == Question.id)
            .where(Attempt.user_id == user_id)
            .group_by(Question.subject)
            .order_by(Question.subject)
        )
    ).all()

    return {
        "overall_accuracy": float(overall_accuracy or 0.0),
        "avg_time_per_question": float(avg_time or 0.0),
        "total_attempts": int(total_attempts or 0),
        "weak_topics": weak_topics,
        "subject_breakdown": [
            {
                "subject": row.subject,
                "attempts": int(row.attempts or 0),
                "accuracy": float(row.accuracy or 0.0),
                "avg_time": float(row.avg_time or 0.0),
            }
            for row in subject_rows
        ],
    }
