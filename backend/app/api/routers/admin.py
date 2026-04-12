from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
import json

from app.api.deps import get_current_user
from app.db.session import get_session
from app.models.models import Announcement, Question, User
from app.schemas.schemas import AdminStatsOut, AnnouncementCreate, AnnouncementOut, QuestionCreate, BulkQuestionUploadResponse

router = APIRouter(prefix="/admin", tags=["admin"])

def require_admin(user: User):
    if not user.is_admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin privileges required")

@router.get("/stats", response_model=AdminStatsOut)
async def get_admin_stats(
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user)
) -> AdminStatsOut:
    require_admin(current_user)
    total_users = await session.scalar(select(func.count(User.id)))
    premium_users = await session.scalar(select(func.count(User.id)).where(User.is_premium == True))
    total_questions = await session.scalar(select(func.count(Question.id)))
    
    return AdminStatsOut(
        total_users=total_users or 0,
        premium_users=premium_users or 0,
        total_questions=total_questions or 0,
    )


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
