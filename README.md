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

## Frontend

Path: `lib/`

### Setup

1. Install Flutter dependencies:
   - `flutter pub get`
2. Run app and set API base URL:
   - `flutter run --dart-define=API_BASE_URL=http://localhost:8000`
   - For Android emulator, use `http://10.0.2.2:8000`.

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
