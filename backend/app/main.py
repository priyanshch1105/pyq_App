from fastapi import FastAPI

from app.api.routers import auth, practice, questions, recommendations, seed
from app.models.models import Base
from app.db.session import engine

app = FastAPI(title="PYQ Platform API", version="1.0.0")

app.include_router(auth.router)
app.include_router(questions.router)
app.include_router(practice.router)
app.include_router(recommendations.router)
app.include_router(seed.router)

@app.on_event("startup")
async def startup() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


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
