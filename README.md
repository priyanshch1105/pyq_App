# PYQ Platform (Flutter + FastAPI + PostgreSQL)

Production-focused full-stack scaffold for a paid Previous Year Questions platform across UPSC, JEE, NEET, NDA, and SSC.

## Tech Stack

- Frontend: Flutter + Riverpod + Dio
- Backend: FastAPI (async) + SQLAlchemy async
- Database: PostgreSQL
- Auth: JWT + bcrypt password hashing

## Backend

Path: `backend/`

### Run locally

1. Create database `pyq_db` in PostgreSQL.
2. Install dependencies:
   - `pip install -r backend/requirements.txt`
3. Apply schema:
   - `psql -d pyq_db -f backend/migrations/001_init.sql`
4. Start API:
   - `uvicorn app.main:app --reload --app-dir backend`

### Docker

- `cd backend`
- `docker compose up --build`

API base: `http://localhost:8000`

### Render notes

- Set `DATABASE_URL` in Render service environment.
- Use Render Postgres **internal** URL (not localhost).
- The backend normalizes `postgres://` and `postgresql://` to `postgresql+asyncpg://` automatically.
- On Render, local `.env` is ignored and only Render environment variables are used.
- On startup, backend also ensures legacy databases get missing `users.is_admin` column.
- Ensure `SECRET_KEY` is set to a strong random value in production.

## Frontend

Path: `lib/`

### Setup

1. Install Flutter dependencies:
   - `flutter pub get`
2. Run app and set API base URL:
   - Render (recommended for phone + emulator):
        - `flutter run --dart-define=API_BASE_URL=https://pyq-app-0h48.onrender.com`
   - Local backend on Android emulator:
     - `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`
   - Local backend on physical phone (same Wi-Fi):
     - `flutter run --dart-define=API_BASE_URL=http://<YOUR_PC_LAN_IP>:8000`

## Implemented Modules

- Auth: `POST /auth/register`, `POST /auth/login`
- Questions: `GET /questions`, `GET /questions/{id}` with filter + pagination
- Practice: `POST /attempt`, `GET /performance`
- Recommendations: `GET /recommendations` (premium-only)
- Premium gating for free vs full access
- Recommendation score:
  - `score = (1 - accuracy_topic) + normalized_time + difficulty_weight`

## UI Flow

- Login/Register
- Exam Selection
- Question List
- Practice (submit answer + explanation)
- Analytics Dashboard
- Subscription page

## Notes

- Backend currently auto-creates tables on startup for quick bootstrap.
- SQL migration is also included for deployment pipelines.
- Add seed data for `questions` before practice flow.
