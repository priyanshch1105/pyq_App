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
