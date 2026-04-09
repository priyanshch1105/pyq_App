from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.session import get_session
from app.models.models import User
from app.schemas.schemas import LoginRequest, RegisterRequest, TokenResponse, UserProfileOut
from app.services.services import login_user, register_user

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse)
async def register(payload: RegisterRequest, session: AsyncSession = Depends(get_session)) -> TokenResponse:
    token = await register_user(session, payload.email, payload.password)
    return TokenResponse(access_token=token)


@router.post("/login", response_model=TokenResponse)
async def login(payload: LoginRequest, session: AsyncSession = Depends(get_session)) -> TokenResponse:
    token = await login_user(session, payload.email, payload.password)
    return TokenResponse(access_token=token)


@router.get("/me", response_model=UserProfileOut)
async def get_me(current_user: User = Depends(get_current_user)) -> UserProfileOut:
    return current_user
