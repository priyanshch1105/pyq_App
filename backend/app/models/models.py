import uuid
from datetime import datetime, timezone

from sqlalchemy import JSON, Boolean, DateTime, Float, ForeignKey, Index, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(Text, nullable=False)
    is_premium: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)


class Question(Base):
    __tablename__ = "questions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    exam: Mapped[str] = mapped_column(String(32), index=True)
    subject: Mapped[str] = mapped_column(String(128), index=True)
    topic: Mapped[str] = mapped_column(String(128), index=True)
    year: Mapped[int] = mapped_column(Integer, index=True)
    difficulty: Mapped[int] = mapped_column(Integer, default=1)
    question: Mapped[str] = mapped_column(Text)
    options: Mapped[dict] = mapped_column(JSON)
    correct_answer: Mapped[str] = mapped_column(String(32))
    explanation: Mapped[str] = mapped_column(Text)
    weightage: Mapped[float] = mapped_column(Float, default=1.0)

    __table_args__ = (
        Index("ix_questions_exam_topic_year", "exam", "topic", "year"),
    )


class Attempt(Base):
    __tablename__ = "attempts"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), index=True)
    question_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("questions.id"), index=True)
    topic: Mapped[str] = mapped_column(String(128), index=True)
    is_correct: Mapped[bool] = mapped_column(Boolean, nullable=False)
    time_taken: Mapped[float] = mapped_column(Float, nullable=False)
    skipped: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None), index=True)


class TopicStat(Base):
    __tablename__ = "topic_stats"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True
    )
    topic: Mapped[str] = mapped_column(String(128), primary_key=True)
    accuracy: Mapped[float] = mapped_column(Float, default=0.0)
    avg_time: Mapped[float] = mapped_column(Float, default=0.0)
    attempts: Mapped[int] = mapped_column(Integer, default=0)

class Announcement(Base):
    __tablename__ = "announcements"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    is_premium_only: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None), index=True)
