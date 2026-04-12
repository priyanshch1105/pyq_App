import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.api.routers import admin, announcements, auth, practice, questions, recommendations, seed
from app.db import session as db_session
from app.models.models import Base

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


async def _initialize_database() -> None:
    async with db_session.engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        if db_session.current_database_url.startswith("postgresql+asyncpg://"):
            # Keep old deployed Postgres databases compatible with current ORM models.
            await conn.execute(
                text(
                    "ALTER TABLE users "
                    "ADD COLUMN IF NOT EXISTS is_premium BOOLEAN NOT NULL DEFAULT FALSE"
                )
            )
            await conn.execute(
                text(
                    "ALTER TABLE users "
                    "ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT FALSE"
                )
            )

@app.on_event("startup")
async def startup() -> None:
    try:
        await _initialize_database()
    except Exception:
        if db_session.current_database_url.startswith("postgresql+asyncpg://"):
            logger.exception("Primary Postgres connection failed at startup")
            logger.warning("Falling back to SQLite because Postgres is unreachable")
            await db_session.switch_database_url(db_session.SQLITE_FALLBACK_URL)
            await _initialize_database()
        else:
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
