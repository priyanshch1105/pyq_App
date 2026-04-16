# PYQ Admin Panel

React + Vite admin frontend for the existing FastAPI backend.

## Run

1. `cd admin-panel`
2. `npm install`
3. Copy `.env.example` to `.env` if needed and set `VITE_API_BASE_URL`
4. `npm run dev`

## Features

- Admin login using existing `/auth/login`
- Live dashboard with active users and active study rooms
- Broadcast announcement form for all users or premium users
- Bulk JSON question upload using existing backend import endpoint
