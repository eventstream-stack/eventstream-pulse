# Deployment & Operations Guide

## Critical Warnings

### NEVER Run `docker compose down -v`

The `-v` flag removes Docker volumes, which **permanently deletes all database data**.

```bash
# DANGEROUS - will delete all data:
docker compose down -v        # DO NOT USE
docker compose down --volumes # DO NOT USE

# SAFE - preserves data:
docker compose down           # OK - stops containers, keeps volumes
docker compose restart        # OK - restarts containers
```

If you accidentally run `down -v`, the database volume will be recreated empty on next startup. **There is no recovery without a backup.**

---

## Local Development

### Docker (PostgreSQL)

```bash
# Start containers
docker compose -f docker-compose.dev.yml up -d

# Run migrations
docker compose -f docker-compose.dev.yml exec web python manage.py migrate

# Seed target apps
docker compose -f docker-compose.dev.yml exec web python manage.py seed_apps

# Create admin user
docker compose -f docker-compose.dev.yml exec web python manage.py createsuperuser

# View logs
docker compose -f docker-compose.dev.yml logs -f web
```

**Access:**
- Admin: http://localhost:8000/admin/
- API: http://localhost:8000/api/messages/?app_id=brighton&token=pulse_dev_token

### Without Docker (SQLite)

```bash
cd pulse_admin
export USE_SQLITE=True
python manage.py migrate
python manage.py seed_apps
python manage.py createsuperuser
python manage.py runserver
```

---

## Production Deployment

### Initial Setup

```bash
# Clone and configure
cd /path/to/eventstream-pulse
cp .env.example .env
# Edit .env with production values

# Start services
docker compose up -d

# Initialize database (migrations run automatically at startup)
docker compose exec web python manage.py seed_apps
docker compose exec web python manage.py createsuperuser
```

**Note:** The entrypoint script automatically runs `migrate` and `collectstatic` on container startup, so you only need to run `seed_apps` and `createsuperuser` manually.

### Updating Production

```bash
docker compose pull
docker compose down && docker compose up -d
docker compose exec web python manage.py migrate
```

---

## Database Operations

### Backup (Do This Regularly!)

```bash
# Create backup
docker compose exec db pg_dump -U pulse_admin pulse_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Or for dev environment
docker compose -f docker-compose.dev.yml exec db pg_dump -U pulse_admin pulse_db > backup.sql
```

### Restore from Backup

```bash
# Restore (will overwrite current data)
cat backup.sql | docker compose exec -T db psql -U pulse_admin pulse_db
```

### Django Shell Access

```bash
docker compose exec web python manage.py shell
```

### Reset Admin Password

```bash
docker compose exec web python manage.py shell -c "
from django.contrib.auth.models import User
u = User.objects.get(username='admin')
u.set_password('newpassword')
u.save()
"
```

---

## Troubleshooting

### Static Files Not Loading (No CSS)

Static files are collected automatically on container startup. If files are missing:

```bash
# Restart container to re-run collectstatic
docker compose restart web

# Or manually collect if needed
docker compose exec web python manage.py collectstatic --noinput
```

### Can't Connect to Database

1. Check container status: `docker compose ps`
2. Check db logs: `docker compose logs db`
3. Verify credentials in `.env` match `docker-compose.yml`

### Message Not Showing in API

Check in Django admin:
1. Is `is_active` checked?
2. Is `start_date` in the past?
3. Is `end_date` null or in the future?
4. Is the correct app selected in "Target apps"?

### Invalid Token Error

- Verify `API_TOKEN` in `.env` matches your request
- Restart web container after changing `.env`: `docker compose restart web`

---

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SECRET_KEY` | Django secret key | Yes (production) |
| `DEBUG` | Debug mode (`True`/`False`) | No (default: True) |
| `ALLOWED_HOSTS` | Comma-separated hostnames | Yes (production) |
| `USE_SQLITE` | Use SQLite instead of PostgreSQL | No |
| `POSTGRES_DB` | Database name | Yes (if PostgreSQL) |
| `POSTGRES_USER` | Database user | Yes (if PostgreSQL) |
| `POSTGRES_PASSWORD` | Database password | Yes (if PostgreSQL) |
| `POSTGRES_HOST` | Database host | Yes (if PostgreSQL) |
| `API_TOKEN` | API authentication token | Yes |
| `CSRF_TRUSTED_ORIGINS` | Trusted origins for CSRF | Yes (production) |

---

## SSL Certificate Renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal

# Restart nginx after renewal
docker compose restart nginx
```
