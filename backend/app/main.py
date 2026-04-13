import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select

from app.api.routers import admin, announcements, auth, practice, questions, recommendations, seed
from app.db.session import AsyncSessionLocal, engine
from app.models.models import Base, Question
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

app.include_router(auth.router)
app.include_router(questions.router)
app.include_router(practice.router)
app.include_router(recommendations.router)
app.include_router(seed.router)
app.include_router(admin.router)
app.include_router(announcements.router)

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
        "health": "/health"
    }


@app.get("/favicon.ico", include_in_schema=False)
async def favicon() -> None:
    return None


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}
