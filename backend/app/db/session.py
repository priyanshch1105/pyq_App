from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import settings

SQLITE_FALLBACK_URL = "sqlite+aiosqlite:///./pyq.db"


def _build_engine(database_url: str):
    return create_async_engine(database_url, future=True, echo=False)


current_database_url = settings.database_url
engine = _build_engine(current_database_url)
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)


async def switch_database_url(database_url: str) -> None:
    global engine, AsyncSessionLocal, current_database_url
    old_engine = engine
    current_database_url = database_url
    engine = _build_engine(database_url)
    AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
    await old_engine.dispose()


async def get_session() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session
