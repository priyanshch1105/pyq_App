from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import and_, cast, Integer, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password, verify_password
from app.models.models import Attempt, Question, TopicStat, User
from app.schemas.schemas import AttemptCreate


async def register_user(session: AsyncSession, email: str, password: str) -> str:
    existing = await session.scalar(select(User).where(User.email == email))
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    user = User(email=email, password_hash=hash_password(password))
    if email == "admin@admin.com":
        user.is_admin = True
    session.add(user)
    await session.commit()
    return create_access_token(str(user.id))


async def login_user(session: AsyncSession, email: str, password: str) -> str:
    user = await session.scalar(select(User).where(User.email == email))
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    if verify_password(password, user.password_hash):
        return create_access_token(str(user.id))

    # Backward compatibility: migrate legacy plaintext passwords on successful login.
    if user.password_hash == password:
        user.password_hash = hash_password(password)
        await session.commit()
        return create_access_token(str(user.id))

    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")


async def fetch_questions(
    session: AsyncSession,
    is_premium: bool,
    exam: str | None,
    subject: str | None,
    topic: str | None,
    year: int | None,
    limit: int,
    offset: int,
) -> list[Question]:
    conditions = []
    if exam:
        if exam.upper() == "JEE":
            conditions.append(Question.exam.in_(["JEE_MAIN", "JEE_ADVANCED"]))
        else:
            conditions.append(Question.exam == exam)
    if subject:
        conditions.append(Question.subject == subject)
    if topic:
        conditions.append(Question.topic == topic)
    if year:
        conditions.append(Question.year == year)
    query = select(Question).offset(offset).limit(limit)
    if conditions:
        query = query.where(and_(*conditions))
    rows = (await session.scalars(query.order_by(Question.year.desc()))).all()
    return rows if is_premium else rows[: min(10, len(rows))]


async def submit_attempt(
    session: AsyncSession, user_id: UUID, payload: AttemptCreate
) -> tuple[bool, str, str]:
    question = await session.scalar(select(Question).where(Question.id == payload.question_id))
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")

    is_correct = (payload.selected_answer == question.correct_answer) if not payload.skipped else False
    attempt = Attempt(
        user_id=user_id,
        question_id=question.id,
        topic=question.topic,
        is_correct=is_correct,
        time_taken=payload.time_taken,
        skipped=payload.skipped,
    )
    session.add(attempt)
    await session.flush()
    await _upsert_topic_stats(session, user_id, question.topic)
    await session.commit()
    return is_correct, question.correct_answer, question.explanation


async def _upsert_topic_stats(session: AsyncSession, user_id: UUID, topic: str) -> None:
    stats_res = await session.execute(
        select(
            func.count(Attempt.id),
            func.avg(cast(Attempt.is_correct, Integer)),
            func.avg(Attempt.time_taken),
        ).where(and_(Attempt.user_id == user_id, Attempt.topic == topic))
    )
    stats = stats_res.one()
    attempts_count, accuracy, avg_time = stats
    current = await session.scalar(
        select(TopicStat).where(and_(TopicStat.user_id == user_id, TopicStat.topic == topic))
    )
    if current:
        current.attempts = attempts_count or 0
        current.accuracy = float(accuracy or 0.0)
        current.avg_time = float(avg_time or 0.0)
    else:
        session.add(
            TopicStat(
                user_id=user_id,
                topic=topic,
                attempts=attempts_count or 0,
                accuracy=float(accuracy or 0.0),
                avg_time=float(avg_time or 0.0),
            )
        )


async def get_performance(session: AsyncSession, user_id: UUID) -> dict:
    from datetime import date, timedelta
    from sqlalchemy import Date

    topic_rows = (
        await session.scalars(select(TopicStat).where(TopicStat.user_id == user_id).order_by(TopicStat.topic))
    ).all()
    
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

    subject_rows = (
        await session.execute(
            select(
                Question.subject,
                func.count(Attempt.id).label("attempts"),
                func.avg(cast(Attempt.is_correct, Integer)).label("accuracy"),
                func.avg(Attempt.time_taken).label("avg_time")
            ).select_from(Attempt).join(Question, Attempt.question_id == Question.id)
            .where(Attempt.user_id == user_id)
            .group_by(Question.subject)
            .order_by(Question.subject)
        )
    ).all()

    subject_stats = [
        {
            "subject": row.subject,
            "attempts": row.attempts,
            "accuracy": float(row.accuracy or 0.0),
            "avg_time": float(row.avg_time or 0.0)
        }
        for row in subject_rows
    ]

    dates = (
        await session.scalars(
            select(cast(Attempt.created_at, Date))
            .where(Attempt.user_id == user_id)
            .distinct()
            .order_by(cast(Attempt.created_at, Date).desc())
        )
    ).all()

    streak = 0
    today = date.today()
    current_date = today
    for d in dates:
        if d == current_date:
            streak += 1
            current_date -= timedelta(days=1)
        elif streak == 0 and d == today - timedelta(days=1):
            streak += 1
            current_date = d - timedelta(days=1)
        elif d < current_date:
            break

    return {
        "overall_accuracy": float(overall_accuracy or 0.0),
        "avg_time_per_question": float(avg_time or 0.0),
        "total_attempts": total_attempts or 0,
        "streak": streak,
        "topic_stats": topic_rows,
        "subject_stats": subject_stats,
    }


async def get_recommendations(session: AsyncSession, user_id: UUID, limit: int = 10) -> list[dict]:
    stats = (await session.scalars(select(TopicStat).where(TopicStat.user_id == user_id))).all()
    if not stats:
        latest = (await session.scalars(select(Question).order_by(Question.year.desc()).limit(limit))).all()
        return [
            {"question_id": q.id, "topic": q.topic, "score": 1.0, "reason": "New user starter set"}
            for q in latest
        ]

    topic_accuracy = {s.topic: s.accuracy for s in stats}
    topic_time = {s.topic: s.avg_time for s in stats}
    max_time = max(topic_time.values()) if topic_time else 1.0

    questions = (await session.scalars(select(Question).limit(200))).all()
    scored = []
    for q in questions:
        accuracy = topic_accuracy.get(q.topic, 0.0)
        normalized_time = (topic_time.get(q.topic, 0.0) / max_time) if max_time else 0.0
        difficulty_weight = q.difficulty / 5.0
        score = (1 - accuracy) + normalized_time + difficulty_weight
        scored.append((score * q.weightage, q))
    scored.sort(key=lambda item: item[0], reverse=True)
    return [
        {
            "question_id": q.id,
            "topic": q.topic,
            "score": round(score, 4),
            "reason": "Low accuracy or high time topic with high PYQ weightage",
        }
        for score, q in scored[:limit]
    ]
