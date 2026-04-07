from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.session import get_session
from app.services.seed_data import seed_mock_jee_questions

router = APIRouter(prefix="/seed", tags=["seed"])


@router.post("/mock-jee")
async def seed_mock_jee(
    session: AsyncSession = Depends(get_session),
    x_admin_seed_key: str | None = Header(default=None),
) -> dict:
    if x_admin_seed_key != settings.admin_seed_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid admin seed key",
        )
    result = await seed_mock_jee_questions(session)
    return {"message": "Mock JEE data seeded", **result}
