import logging
from uuid import UUID

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from jose import JWTError, jwt
from sqlalchemy import select

from app.api.router import api_router
from app.core.config import settings
from app.db.session import AsyncSessionLocal, engine
from app.models.models import Base, Question, User
from app.services.admin_realtime import admin_realtime_tracker
from app.services.seed_data import seed_platform_questions

app = FastAPI(title="PYQ Platform API", version="1.0.0")
logger = logging.getLogger(__name__)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Allow Vite frontend
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)
app.include_router(api_router, prefix="/api/v1")


@app.middleware("http")
async def track_authenticated_activity(request: Request, call_next):
    auth_header = request.headers.get("authorization", "")
    if auth_header.lower().startswith("bearer "):
        token = auth_header.split(" ", 1)[1].strip()
        try:
            payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
            user_id = payload.get("sub")
            if user_id:
                async with AsyncSessionLocal() as session:
                    user = await session.scalar(select(User).where(User.id == UUID(user_id)))
                    if user:
                        await admin_realtime_tracker.touch_user(user.id, user.email)
        except JWTError:
            pass
        except Exception:
            logger.exception("Failed to track authenticated user activity")
    return await call_next(request)

@app.on_event("startup")
async def startup() -> None:
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        async with AsyncSessionLocal() as session:
            existing = await session.scalar(select(Question.id).limit(1))
            if existing is None:
                result = await seed_platform_questions(session)
                logger.info(
                    "Seeded startup questions inserted=%s skipped=%s total=%s",
                    result["inserted"],
                    result["skipped"],
                    result["total"],
                )
    except Exception:
        logger.exception("Database startup initialization failed")
        raise


@app.get("/")
async def root() -> dict:
    return {
        "message": "Welcome to PYQ Platform API",
        "docs": "/docs",
        "health": "/health",
        "versioned_api": "/api/v1",
    }


@app.get("/favicon.ico", include_in_schema=False)
async def favicon() -> None:
    return None

