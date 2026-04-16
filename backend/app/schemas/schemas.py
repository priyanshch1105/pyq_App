from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)


class LoginRequest(RegisterRequest):
    pass


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class QuestionOut(BaseModel):
    id: UUID
    exam: str
    subject: str
    topic: str
    year: int
    difficulty: int
    question: str
    options: dict
    explanation: str | None = None

    class Config:
        from_attributes = True


class AttemptCreate(BaseModel):
    question_id: UUID
    selected_answer: str | None = None
    time_taken: float
    skipped: bool = False


class AttemptResult(BaseModel):
    is_correct: bool
    correct_answer: str
    explanation: str


class TopicStatOut(BaseModel):
    topic: str
    accuracy: float
    avg_time: float
    attempts: int


class PerformanceOut(BaseModel):
    overall_accuracy: float
    avg_time_per_question: float
    topic_stats: list[TopicStatOut]


class RecommendationOut(BaseModel):
    question_id: UUID
    topic: str
    score: float
    reason: str


class AttemptOut(BaseModel):
    id: UUID
    user_id: UUID
    question_id: UUID
    topic: str
    is_correct: bool
    time_taken: float
    skipped: bool
    created_at: datetime

class QuestionCreate(BaseModel):
    exam: str
    subject: str
    topic: str
    year: int
    difficulty: int = 1
    question: str
    options: dict
    correct_answer: str
    explanation: str

class AnnouncementCreate(BaseModel):
    title: str
    content: str
    is_premium_only: bool = False

class AnnouncementOut(BaseModel):
    id: UUID
    title: str
    content: str
    is_premium_only: bool
    created_at: datetime

    class Config:
        from_attributes = True


class BulkQuestionUploadResponse(BaseModel):
    total_processed: int
    inserted: int
    skipped: int
    failed: int
    errors: list[dict] = []


class AdminStatsOut(BaseModel):
    total_users: int
    premium_users: int
    total_questions: int
    active_users: int = 0
    active_rooms: int = 0
    total_announcements: int = 0

    class Config:
        from_attributes = True


class ActiveUserSampleOut(BaseModel):
    user_id: UUID
    email: str
    last_seen: datetime


class AdminRealtimeSnapshotOut(BaseModel):
    active_users: int
    active_rooms: int
    tracked_users: list[ActiveUserSampleOut]

class UserProfileOut(BaseModel):
    id: UUID
    email: str
    is_premium: bool
    is_admin: bool
    
    class Config:
        from_attributes = True

