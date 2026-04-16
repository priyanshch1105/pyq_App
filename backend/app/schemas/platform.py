from datetime import datetime
from enum import Enum
from uuid import UUID

from pydantic import BaseModel, Field


class DoubtStatus(str, Enum):
    pending = "pending"
    answered = "answered"
    resolved = "resolved"


class ResponderType(str, Enum):
    ai = "ai"
    mentor = "mentor"
    user = "user"


class QuestionType(str, Enum):
    mcq = "mcq"
    numerical = "numerical"
    theory = "theory"


class DoubtCreate(BaseModel):
    subject: str = Field(min_length=2, max_length=128)
    chapter: str = Field(min_length=2, max_length=128)
    question_type: QuestionType
    question_text: str = Field(min_length=1)
    image_url: str | None = None


class DoubtUpdateStatus(BaseModel):
    status: DoubtStatus


class DoubtResponseCreate(BaseModel):
    answer_text: str = Field(min_length=1)
    responder_type: ResponderType = ResponderType.mentor


class DoubtResponseOut(BaseModel):
    id: UUID
    doubt_id: UUID
    responder_id: UUID | None = None
    responder_type: ResponderType
    answer_text: str
    helpful_count: int
    created_at: datetime

    class Config:
        from_attributes = True


class DoubtOut(BaseModel):
    id: UUID
    user_id: UUID
    subject: str
    chapter: str
    question_type: QuestionType
    question_text: str
    image_url: str | None = None
    status: DoubtStatus
    created_at: datetime

    class Config:
        from_attributes = True


class DoubtDetailOut(DoubtOut):
    responses: list[DoubtResponseOut] = []


class StudyRoomCreate(BaseModel):
    name: str = Field(min_length=3, max_length=100)
    exam: str = Field(min_length=2, max_length=32)


class StudyRoomOut(BaseModel):
    id: UUID
    name: str
    exam: str
    created_by: UUID
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class RoomMessageCreate(BaseModel):
    message: str = Field(min_length=1, max_length=2000)


class RoomMessageOut(BaseModel):
    id: UUID
    room_id: UUID
    user_id: UUID
    message: str
    timestamp: datetime

    class Config:
        from_attributes = True


class PredictedTestMeta(BaseModel):
    exam: str
    difficulty: str
    prediction_accuracy: float


class PredictedQuestionOut(BaseModel):
    id: UUID
    exam: str
    subject: str
    topic: str
    year: int
    difficulty: int
    question: str
    options: dict


class PredictedTestOut(BaseModel):
    meta: PredictedTestMeta
    questions: list[PredictedQuestionOut]


class ChatRequest(BaseModel):
    message: str = Field(min_length=1)
    exam: str | None = None


class ChatImageRequest(BaseModel):
    image_url: str = Field(min_length=1)
    prompt: str | None = None
    exam: str | None = None


class ChatResponse(BaseModel):
    answer: str
    hints: list[str]


class PerformanceAnalyticsOut(BaseModel):
    overall_accuracy: float
    avg_time_per_question: float
    total_attempts: int
    weak_topics: list[str]
    subject_breakdown: list[dict]


class SignedUploadRequest(BaseModel):
    filename: str = Field(min_length=1)
    content_type: str = Field(min_length=1)
    folder: str = Field(default="doubts", min_length=1)
    provider: str = Field(default="cloudinary")


class SignedUploadResponse(BaseModel):
    provider: str
    upload_url: str
    public_id: str
    timestamp: int
    api_key: str
    signature: str
    folder: str
