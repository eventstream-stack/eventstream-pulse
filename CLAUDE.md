# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Eventstream Pulse is a centralized in-app messaging system for EventStream city apps. It replaces Firebase In-App Messaging with a self-hosted Django backend that serves targeted messages (modals, banners, bottom sheets, full-screen announcements) to Flutter mobile apps.

**Production URL:** https://monitor.eventstream.tech

## Common Commands

### Local Development (Docker)
```bash
docker compose -f docker-compose.dev.yml up -d
docker compose -f docker-compose.dev.yml exec web python manage.py migrate
docker compose -f docker-compose.dev.yml exec web python manage.py seed_apps
docker compose -f docker-compose.dev.yml exec web python manage.py createsuperuser
```

### Local Development (SQLite)
```bash
cd pulse_admin
python manage.py runserver
```

### Production Deployment
```bash
docker compose pull                    # Pull latest from Docker Hub
docker compose down && docker compose up -d
# Migrations run automatically at startup via entrypoint.sh
```

### Database Operations
```bash
docker compose exec db pg_dump -U pulse_admin pulse_db > backup.sql
docker compose exec web python manage.py shell
```

### Testing API Endpoints
```bash
# Fetch messages for an app
curl "http://localhost:8000/api/messages/?app_id=brighton&token=pulse_dev_token"

# Record impression
curl -X POST "http://localhost:8000/api/messages/1/impression/?app_id=brighton&token=pulse_dev_token"

# Record tap
curl -X POST "http://localhost:8000/api/messages/1/tap/?app_id=brighton&token=pulse_dev_token"
```

## Architecture

```
Django Admin → PostgreSQL → REST API → Flutter Apps
     ↓              ↓           ↓
 messages_app   PulseMessage   /api/messages/
 analytics      Impressions    /api/messages/{id}/impression/
                Taps           /api/messages/{id}/tap/
```

**Key Django Apps:**
- `messages_app` - Core models (PulseMessage, TargetApp), API views, admin, serializers
- `analytics` - MessageImpression and MessageTap tracking

**API Authentication:** Token-based via `?token=` query parameter, validated against `API_TOKEN` env var in `TokenValidationMixin` (`views.py:12`).

**Message Visibility Logic:** `PulseMessage.is_currently_active()` checks: `is_active=True`, `start_date <= now`, and (`end_date` is null OR `end_date > now`).

## Key Files

| File | Purpose |
|------|---------|
| `pulse_admin/messages_app/models.py` | PulseMessage, TargetApp models with MESSAGE_TYPES and PRIORITY_LEVELS |
| `pulse_admin/messages_app/views.py` | ActiveMessagesView, RecordImpressionView, RecordTapView |
| `pulse_admin/messages_app/serializers.py` | DRF serializers for API responses |
| `pulse_admin/messages_app/admin.py` | Jazzmin admin with status badges and live preview |
| `pulse_admin/messages_app/forms.py` | Custom admin form with ColorWidget for color pickers |
| `pulse_admin/pulse_admin/settings.py` | Django settings, Jazzmin config, database switching |
| `entrypoint.sh` | Container startup script (runs migrations and collectstatic) |
| `flutter/lib/` | Flutter integration files for city apps |

## Environment Variables

Required for production:
- `SECRET_KEY`, `DEBUG=False`, `ALLOWED_HOSTS`
- `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_HOST`
- `API_TOKEN`, `CSRF_TRUSTED_ORIGINS`

Use `USE_SQLITE=True` for local development without Docker.

## CI/CD

GitHub Actions (`.github/workflows/docker-publish.yml`) builds and pushes to `bautizar/eventstream-pulse` on Docker Hub on every push to main. Tags: `latest` and commit SHA. Docker Hub repo is private - server must `docker login` before pulling.

## Target App IDs

`brighton`, `edinburgh`, `manchester`, `cardiff`, `kilkenny`, `york`

Managed via `seed_apps` management command or Django admin at Target Apps.
