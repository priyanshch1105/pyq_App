from fastapi import APIRouter

from app.api.routers import admin, analytics, announcements, auth, chat, doubts, health, media, mock, practice, questions, recommendations, rooms, seed

api_router = APIRouter()

for module in (auth, questions, practice, recommendations, seed, admin, announcements, health, doubts, rooms, mock, chat, analytics, media):
    api_router.include_router(module.router)
