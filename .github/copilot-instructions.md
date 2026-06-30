# PropertyHub Uganda Copilot Instructions

This workspace contains a Flutter mobile app and a FastAPI backend for PropertyHub Uganda.

## Project overview
- Frontend: Flutter app in the repository root with screens, widgets, models, and BLoC state management.
- Backend: FastAPI service in the backend/ folder with SQLAlchemy models, Pydantic schemas, services, API routes, and background workers.
- The app is for property listings, bookings, payments, search, messaging, and admin workflows.

## Working style
- Prefer small, focused changes that fit the existing architecture.
- Keep frontend and backend changes consistent when a feature touches both layers.
- Reuse existing patterns instead of introducing new frameworks or abstractions.
- Do not hardcode secrets, API keys, or credentials.
- Preserve async and dependency-injection patterns already used in the backend.

## Frontend guidance
- Flutter code lives under lib/.
- Follow the existing structure for screens, widgets, models, bloc, and navigation.
- Use Material widgets and the existing app styling conventions.
- When adding a new screen or feature, keep navigation updates consistent with the router setup.
- Prefer existing API client patterns and shared utility code over ad hoc networking.

## Backend guidance
- FastAPI code lives under backend/app/.
- Keep route handlers in backend/app/api/, business logic in backend/app/services/, and database models in backend/app/models/.
- Use Pydantic schemas for request/response validation.
- Preserve existing authentication, permission, and error-handling patterns.
- For database changes, consider the Alembic migration flow in backend/alembic/.

## Testing expectations
- Backend: prefer pytest tests under backend/tests/.
- Frontend: prefer flutter_test tests under test/.
- When fixing a bug or adding a feature, add or update a relevant test when practical.

## Common commands
- Frontend: flutter pub get, flutter test, flutter run
- Backend: cd backend && pytest, cd backend && uvicorn app.main:app --reload

## Response expectations
- When helping with this project, explain changes clearly and mention the relevant files.
- Prefer actionable guidance with concise implementation steps.
