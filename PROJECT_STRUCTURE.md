# Project Structure

This repository is organized as a multi-app workspace:

- Flutter mobile app: `lib/`
- Python backend API: `backend/`
- React admin panel: `admin-panel/`

## Flutter (`lib/`)

Use feature-first clean architecture:

- `app/`: app bootstrap, DI, routing
- `core/`: cross-cutting technical layers
- `shared/`: reusable helpers and extensions
- `features/<feature>/`: feature modules

Recommended feature layout:

- `data/`: API/local data sources, DTOs, repository implementations
- `domain/`: entities, repository contracts, use cases
- `presentation/`: screens, widgets, state/controllers

## Backend (`backend/`)

Use layered FastAPI structure:

- `app/api/`: routers, request lifecycle dependencies
- `app/core/`: config, security, shared core services
- `app/db/`: database session and persistence setup
- `app/models/`: ORM models
- `app/schemas/`: request/response schemas
- `app/services/`: business services
- `app/repositories/`: data-access abstractions
- `app/tasks/`: background and scheduled jobs
- `tests/unit/`: unit tests
- `tests/integration/`: API and DB integration tests
- `scripts/`: utility scripts for local/devops tasks

## Admin Panel (`admin-panel/src/`)

Use a modular React layout:

- `app/`: app-level providers and root wiring
- `assets/`: static assets used by app
- `components/`: shared UI components
- `config/`: constants and environment configuration
- `features/`: domain feature modules
- `hooks/`: reusable React hooks
- `layouts/`: page shell layouts
- `pages/`: route-level pages
- `routes/`: route objects and guards
- `services/`: API and platform integrations
- `store/`: global state modules
- `utils/`: utility functions

## Migration Note

Current code was not moved automatically to avoid breaking imports. Migrate gradually feature by feature.
