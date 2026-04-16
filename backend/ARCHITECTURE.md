# Scalable Exam Preparation Platform Architecture

This backend supports JEE, NEET, NDA, and UPSC preparation with AI, collaboration, analytics, and adaptive testing.

## 1) System Overview

- API Layer: FastAPI (`app/main.py`, `app/api/routers/*`)
- Domain Services: `app/services/platform.py`
- Persistence: PostgreSQL via SQLAlchemy async
- Realtime: WebSocket room endpoints (`/rooms/ws/{room_id}`)
- AI Layer: pluggable tutor interface (`/chat`, `/chat/image`)
- Analytics: attempt stream + topic aggregation

## 2) Core Modules

### Doubt Solving (DBT)

- Router: `/doubt`
- Models: `Doubt`, `DoubtResponse`
- Features:
  - create doubt with metadata and optional image URL
  - status lifecycle: `pending -> answered -> resolved`
  - follow-up responses and helpful upvotes

### Study Rooms (Realtime)

- Router: `/rooms`, `/rooms/ws/{room_id}`
- Models: `StudyRoom`, `RoomMessage`
- WS events:
  - `user_joined`
  - `send_message` (input)
  - `receive_message` (output)
  - `user_left`

### Predicted Mock Tests

- Router: `/mock/predicted`
- Inputs: user topic stats + exam + target question count
- Selection strategy:
  - 40% weak topics
  - 30% medium difficulty
  - 30% strong/challenging mix

### AI Tutor Chatbot

- Router: `/chat`, `/chat/image`
- Current mode: deterministic tutor responses
- Production upgrade path:
  - request preprocessing
  - prompt templates per exam
  - LLM call (OpenAI/local model)
  - guardrails + response post-processing

### Analytics Engine

- Router: `/analytics/overview`
- Outputs:
  - overall accuracy
  - average time per question
  - weak topics
  - subject-wise breakdown

## 3) Data Model Summary

- `users`: auth, role, premium state
- `questions`: exam-tagged question bank
- `attempts`: user answer events (primary analytics stream)
- `topic_stats`: aggregated user-topic performance
- `doubts`: doubt submissions
- `doubt_responses`: AI/mentor/user responses
- `study_rooms`: collaborative room metadata
- `room_messages`: persisted room chat

## 4) API Summary

- Auth:
  - `POST /auth/login`
  - `POST /auth/register`
- Doubts:
  - `POST /doubt`
  - `GET /doubt/{doubt_id}`
  - `GET /doubt/user/me`
  - `POST /doubt/{doubt_id}/response`
  - `PATCH /doubt/{doubt_id}/status`
  - `POST /doubt/response/{response_id}/helpful`
- Rooms:
  - `POST /rooms`
  - `GET /rooms`
  - `GET /rooms/{room_id}/messages`
  - `POST /rooms/{room_id}/message`
  - `WS /rooms/ws/{room_id}`
- Predicted Mock:
  - `GET /mock/predicted?exam=JEE_MAIN&total_questions=30`
- Chatbot:
  - `POST /chat`
  - `POST /chat/image`
- Analytics:
  - `GET /analytics/overview`

## 5) Scalability Plan

### Stateless API Scaling

- Run multiple FastAPI workers behind load balancer
- Keep API servers stateless
- Move websocket pub/sub to Redis in multi-instance mode

### Realtime Horizontal Scaling

- Add Redis channel layer for WS fan-out
- Keep local in-memory manager only for single node dev

### Data Scaling

- Add indexes for high-cardinality filters (`exam`, `topic`, `created_at`, `user_id`)
- Partition `attempts` and `room_messages` by time when needed
- Add read replicas for analytics-heavy traffic

### AI Scaling

- Add async job queue for expensive LLM/image inference
- Cache frequent concept explanations in Redis
- Add RAG index for PYQ + notes retrieval

### Observability

- Request tracing + structured logs
- Metrics: latency p95, ws active users, mock generation latency, AI response time
- Alerting on error rates and DB saturation

## 6) Security and Governance

- JWT auth on all sensitive routes
- Role checks (`is_admin`) for moderation/mentor workflows
- Input validation (Pydantic)
- Rate limiting recommended for `/chat` and `/rooms/ws/*`
- Content moderation and abuse filters for chat/room messages

## 7) Next Production Steps

1. Replace tutor stub with real LLM provider adapter.
2. Add Redis for websocket broadcast and cache.
3. Add object storage (S3/Cloudinary) signed upload flow for doubt images.
4. Introduce Alembic migrations for new entities.
5. Add background workers for mock generation and AI post-processing.
