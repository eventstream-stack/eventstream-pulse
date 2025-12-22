# Eventstream Pulse

A centralized in-app messaging system for all EventStream city apps. Pulse allows you to send targeted messages (modals, banners, bottom sheets, full-screen announcements) to your mobile apps without app store updates.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [API Documentation](#api-documentation)
- [Admin Guide](#admin-guide)
- [Flutter Integration](#flutter-integration)
- [Deployment](#deployment)
- [CI/CD with GitHub Actions](#cicd-with-github-actions)
- [Troubleshooting](#troubleshooting)

---

## Overview

### What is Pulse?

Pulse is a self-hosted alternative to Firebase In-App Messaging. It provides:

- **Centralized Dashboard**: One admin panel to manage messages for all city apps
- **Targeted Messaging**: Send messages to specific apps (Brighton, Edinburgh, etc.)
- **Multiple Message Types**: Modal, Banner, Bottom Sheet, Full Screen
- **Scheduling**: Set start/end dates for time-limited campaigns
- **Analytics**: Track impressions and tap-through rates
- **No Per-User Costs**: Unlike third-party services, Pulse has no usage-based fees

### Why Pulse?

| Feature | Firebase IAM | OneSignal | Pulse |
|---------|--------------|-----------|-------|
| Per-user pricing | Free (limited) | Yes | No |
| Self-hosted | No | No | Yes |
| Full control | Limited | Limited | Yes |
| Multi-app targeting | Yes | Yes | Yes |
| Custom UI | Limited | Limited | Full |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     ADMIN DASHBOARD                              │
│              https://monitor.eventstream.tech/admin              │
│                                                                  │
│  Create messages with:                                           │
│  - Title, body, image                                            │
│  - CTA button (text + URL/deep link)                             │
│  - Message type (modal, banner, bottom_sheet, full_screen)       │
│  - Target apps (Brighton, Edinburgh, etc.)                       │
│  - Schedule (start/end dates)                                    │
│  - Priority (1-4)                                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       POSTGRESQL DATABASE                        │
│                                                                  │
│  Tables:                                                         │
│  - messages_app_targetapp (city app registry)                    │
│  - messages_app_pulsemessage (messages)                          │
│  - analytics_messageimpression (view tracking)                   │
│  - analytics_messagetap (click tracking)                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         REST API                                 │
│              https://monitor.eventstream.tech/api                │
│                                                                  │
│  GET  /api/messages/?app_id=brighton&token=xxx                   │
│  POST /api/messages/{id}/impression/?app_id=brighton&token=xxx   │
│  POST /api/messages/{id}/tap/?app_id=brighton&token=xxx          │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
   ┌─────────┐          ┌─────────┐          ┌─────────┐
   │Brighton │          │Edinburgh│          │ + more  │
   │   App   │          │   App   │          │  apps   │
   └─────────┘          └─────────┘          └─────────┘
```

### Flow

1. **Admin creates message** in Django admin with targeting rules
2. **Message stored** in PostgreSQL database
3. **App launches** and calls GET `/api/messages/` with its `app_id`
4. **API returns** only active messages targeted to that app
5. **App displays** message using appropriate UI (modal, banner, etc.)
6. **User interacts** - app records impression/tap via POST endpoints
7. **Analytics** visible in admin dashboard

---

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Python 3.11+ (for local development without Docker)

### Local Development with Docker

```bash
# Clone and enter directory
cd eventstream-pulse

# Start containers
docker compose -f docker-compose.dev.yml up -d

# Check status
docker compose -f docker-compose.dev.yml ps

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

### Local Development without Docker

```bash
cd eventstream-pulse

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Configure for SQLite (edit .env)
echo "USE_SQLITE=True" >> .env

# Run migrations
cd pulse_admin
python manage.py migrate
python manage.py seed_apps
python manage.py createsuperuser

# Start server
python manage.py runserver
```

---

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `SECRET_KEY` | Django secret key | - | Yes (production) |
| `DEBUG` | Debug mode | `True` | No |
| `ALLOWED_HOSTS` | Comma-separated hostnames | `localhost,127.0.0.1` | Yes (production) |
| `USE_SQLITE` | Use SQLite instead of PostgreSQL | `False` | No |
| `POSTGRES_DB` | Database name | `pulse_db` | Yes (if PostgreSQL) |
| `POSTGRES_USER` | Database user | `pulse_admin` | Yes (if PostgreSQL) |
| `POSTGRES_PASSWORD` | Database password | - | Yes (if PostgreSQL) |
| `POSTGRES_HOST` | Database host | `localhost` | Yes (if PostgreSQL) |
| `POSTGRES_PORT` | Database port | `5432` | No |
| `API_TOKEN` | API authentication token | `pulse_dev_token` | Yes |
| `CSRF_TRUSTED_ORIGINS` | Trusted origins for CSRF | - | Yes (production) |

### Example .env Files

**Development (SQLite):**
```env
SECRET_KEY=django-insecure-dev-key
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
USE_SQLITE=True
API_TOKEN=pulse_dev_token
```

**Development (Docker):**
```env
SECRET_KEY=django-insecure-dev-key
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
USE_SQLITE=False
POSTGRES_DB=pulse_db
POSTGRES_USER=pulse_admin
POSTGRES_PASSWORD=devpassword
POSTGRES_HOST=db
POSTGRES_PORT=5432
API_TOKEN=pulse_dev_token
```

**Production:**
```env
SECRET_KEY=your-very-secure-random-key-here
DEBUG=False
ALLOWED_HOSTS=monitor.eventstream.tech
USE_SQLITE=False
POSTGRES_DB=pulse_db
POSTGRES_USER=pulse_admin
POSTGRES_PASSWORD=very-secure-password
POSTGRES_HOST=db
POSTGRES_PORT=5432
API_TOKEN=pulse_2025_production_token
CSRF_TRUSTED_ORIGINS=https://monitor.eventstream.tech
```

---

## API Documentation

### Authentication

All API requests require a `token` query parameter:

```
?token=your_api_token
```

### Endpoints

#### GET /api/messages/

Fetch active messages for a specific app.

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `app_id` | string | Yes | App identifier (e.g., `brighton`, `kilkenny`) |
| `token` | string | Yes | API authentication token |

**Example Request:**
```bash
curl "https://monitor.eventstream.tech/api/messages/?app_id=brighton&token=your_token"
```

**Example Response:**
```json
[
  {
    "id": 1,
    "title": "Welcome to Brighton!",
    "body": "Check out the latest events happening in your city.",
    "image_url": "https://example.com/image.jpg",
    "cta_text": "Explore Events",
    "cta_action": "app://events",
    "message_type": "modal",
    "banner_position": "top",
    "priority": 2,
    "is_dismissible": true,
    "target_app_ids": ["brighton"],
    "start_date": "2025-01-01T00:00:00Z",
    "end_date": "2025-02-01T00:00:00Z",
    "is_currently_active": true,
    "created_at": "2024-12-20T10:00:00Z",
    "updated_at": "2024-12-20T10:00:00Z"
  }
]
```

**Response Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Unique message ID |
| `title` | string | Message title (max 100 chars) |
| `body` | string | Message body (max 1000 chars) |
| `image_url` | string | Optional image URL |
| `cta_text` | string | Call-to-action button text |
| `cta_action` | string | URL or deep link for CTA |
| `message_type` | string | `modal`, `banner`, `bottom_sheet`, `full_screen` |
| `banner_position` | string | `top` or `bottom` (for banner type) |
| `priority` | integer | 1-4 (1 = highest priority) |
| `is_dismissible` | boolean | Can user dismiss the message? |
| `target_app_ids` | array | List of targeted app IDs |
| `start_date` | datetime | When message becomes active |
| `end_date` | datetime | When message expires (null = never) |
| `is_currently_active` | boolean | Is message active right now? |

---

#### POST /api/messages/{id}/impression/

Record that a message was displayed to a user.

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `app_id` | string | Yes | App identifier |
| `token` | string | Yes | API authentication token |

**Example Request:**
```bash
curl -X POST "https://monitor.eventstream.tech/api/messages/1/impression/?app_id=brighton&token=your_token"
```

**Example Response:**
```json
{
  "status": "recorded"
}
```

---

#### POST /api/messages/{id}/tap/

Record that a user tapped the CTA button.

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `app_id` | string | Yes | App identifier |
| `token` | string | Yes | API authentication token |

**Example Request:**
```bash
curl -X POST "https://monitor.eventstream.tech/api/messages/1/tap/?app_id=brighton&token=your_token"
```

**Example Response:**
```json
{
  "status": "recorded"
}
```

---

## Admin Guide

### Accessing the Admin

Navigate to `https://monitor.eventstream.tech/admin/` and log in with your credentials.

### Creating a Message

1. Go to **In-App Messages > Pulse Messages > Add**
2. Fill in the **Content** tab:
   - **Title**: Main heading (required, 3-100 characters)
   - **Body**: Message text (required, max 1000 characters)
   - **Image URL**: Optional image to display

3. Fill in **Call to Action** (optional):
   - **CTA Text**: Button label (e.g., "Learn More")
   - **CTA Action**: URL or deep link (e.g., `https://...` or `app://events/123`)

4. Configure **Display Settings**:
   - **Message Type**: Choose how it appears
     - `Modal`: Centered popup (blocks interaction)
     - `Banner`: Non-intrusive bar at top/bottom
     - `Bottom Sheet`: Slides up from bottom
     - `Full Screen`: Takes over entire screen
   - **Banner Position**: Top or bottom (only for banner type)
   - **Priority**: 1 (Critical) to 4 (Low) - lower shows first
   - **Is Dismissible**: Can users close it?

5. Set **Targeting**:
   - Select which apps should show this message
   - Use "Choose all target apps" for broadcast messages

6. Configure **Scheduling**:
   - **Start Date**: When to start showing (use current time or earlier)
   - **End Date**: When to stop (leave blank for no end)
   - **Is Active**: Check to make it live

7. Click **Save**

### Message Status Badges

| Badge | Meaning |
|-------|---------|
| 🟢 **LIVE** | Active and currently showing |
| ⚪ **DRAFT** | Not active (is_active = false) |
| 🔵 **SCHEDULED** | Active but start_date is in future |
| 🔴 **ENDED** | Active but end_date has passed |

### Viewing Analytics

- **Impressions**: How many times the message was shown
- **Taps**: How many times the CTA was clicked
- **CTR**: Click-through rate (taps / impressions × 100)

Analytics are visible in the message list view and in the message detail page under the "Analytics" section.

### Managing Target Apps

Go to **In-App Messages > Target Apps** to:
- Add new city apps
- Deactivate apps (messages won't be sent to inactive apps)
- View app IDs for API configuration

---

## Flutter Integration

### Step 1: Copy Files

Copy the following files from `eventstream-pulse/flutter/lib/` to your Flutter app:

```
your_app/lib/
├── data/
│   ├── models/
│   │   └── pulse_message_model.dart
│   └── datasources/
│       ├── remote/
│       │   └── pulse_remote_datasource.dart
│       └── local/
│           └── pulse_local_storage.dart
├── core/
│   └── services/
│       └── pulse_service.dart
└── presentation/
    ├── riverpod/
    │   └── pulse_providers.dart
    └── widgets/
        └── pulse/
            ├── pulse_modal.dart
            ├── pulse_banner.dart
            ├── pulse_bottom_sheet.dart
            ├── pulse_full_screen.dart
            └── pulse_handler.dart
```

### Step 2: Update App ID

In `pulse_providers.dart`, change the app ID:

```dart
final pulseServiceProvider = Provider<PulseService>((ref) {
  const appId = 'kilkenny'; // Change to your app's ID
  return PulseService(appId: appId);
});
```

**App IDs:**
- `brighton` - The Brighton App
- `edinburgh` - The Edinburgh App
- `manchester` - The Manchester App
- `cardiff` - The Cardiff App
- `kilkenny` - The Kilkenny App
- `york` - The York App

### Step 3: Check Dependencies

Ensure these are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  shared_preferences: ^2.5.2
  cached_network_image: ^3.4.1
  http: ^1.2.2
```

### Step 4: Integrate in Main Navigation

Add pulse message checking to your home screen or main navigation:

```dart
class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasCheckedPulseMessages = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPulseMessages();
    });
  }

  Future<void> _checkPulseMessages() async {
    if (_hasCheckedPulseMessages) return;
    _hasCheckedPulseMessages = true;

    // Wait for app to settle
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final message = ref.read(nextPulseMessageProvider);
    if (message != null) {
      PulseHandler.showMessage(
        context,
        message,
        onDismiss: () => _checkForNextMessage(),
      );
    }
  }

  void _checkForNextMessage() {
    final nextMessage = ref.read(nextPulseMessageProvider);
    if (nextMessage != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          PulseHandler.showMessage(
            context,
            nextMessage,
            onDismiss: () => _checkForNextMessage(),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Your existing build method
  }
}
```

### Step 5: Handle CTA Actions

Update the `_handleCtaAction` method in each widget to handle your deep links:

```dart
void _handleCtaAction(BuildContext context, String? action) {
  if (action == null) return;

  if (action.startsWith('app://')) {
    // Handle deep link
    final path = action.replaceFirst('app://', '');
    Navigator.pushNamed(context, '/$path');
  } else if (action.startsWith('http')) {
    // Handle URL
    launchUrl(Uri.parse(action));
  }
}
```

---

## Deployment

### Production Deployment to monitor.eventstream.tech

#### 1. Prepare the Server

```bash
# SSH to server
ssh user@monitor.eventstream.tech

# Install Docker (if not installed)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install certbot for SSL
sudo apt install certbot
```

#### 2. Set Up SSL Certificates

```bash
# Stop any service on port 80
sudo systemctl stop nginx  # if running

# Get certificate
sudo certbot certonly --standalone -d monitor.eventstream.tech

# Certificates will be at:
# /etc/letsencrypt/live/monitor.eventstream.tech/fullchain.pem
# /etc/letsencrypt/live/monitor.eventstream.tech/privkey.pem
```

#### 3. Deploy Pulse

```bash
# Clone or copy the project
cd /home/user
git clone <your-repo> eventstream-pulse
cd eventstream-pulse

# Create production .env
cp .env.example .env
nano .env
```

Edit `.env` with production values:
```env
SECRET_KEY=generate-a-secure-64-char-key
DEBUG=False
ALLOWED_HOSTS=monitor.eventstream.tech
USE_SQLITE=False
POSTGRES_DB=pulse_db
POSTGRES_USER=pulse_admin
POSTGRES_PASSWORD=very-secure-password-here
POSTGRES_HOST=db
POSTGRES_PORT=5432
API_TOKEN=pulse_2025_production_token
CSRF_TRUSTED_ORIGINS=https://monitor.eventstream.tech
```

#### 4. Build and Start

```bash
# Build containers
docker compose build

# Start services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

#### 5. Initialize Database

```bash
# Run migrations
docker compose exec web python manage.py migrate

# Seed target apps
docker compose exec web python manage.py seed_apps

# Create admin user
docker compose exec web python manage.py createsuperuser
```

#### 6. Verify

- Admin: https://monitor.eventstream.tech/admin/
- API: https://monitor.eventstream.tech/api/messages/?app_id=brighton&token=your_token

### Maintenance Commands

```bash
# View logs
docker compose logs -f web

# Restart services
docker compose restart

# Stop services
docker compose down

# Update code and rebuild
git pull
docker compose build
docker compose up -d

# Database backup
docker compose exec db pg_dump -U pulse_admin pulse_db > backup.sql

# Database restore
cat backup.sql | docker compose exec -T db psql -U pulse_admin pulse_db
```

### SSL Certificate Renewal

Certificates auto-renew with certbot, but verify:

```bash
# Test renewal
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal

# Restart nginx after renewal
docker compose restart nginx
```

---

## CI/CD with GitHub Actions

Pulse uses GitHub Actions to automatically build and push Docker images to Docker Hub.

### How It Works

```
Push to main → GitHub Actions → Docker Hub (bautizar/pulse) → Pull on server
```

### Setup (One-Time)

#### 1. Create Docker Hub Access Token

1. Go to https://hub.docker.com/settings/security
2. Click "New Access Token"
3. Name: `github-actions-pulse`
4. Permissions: **Read & Write**
5. Copy the token (won't be shown again)

#### 2. Add GitHub Secrets

Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:

| Secret Name | Value |
|-------------|-------|
| `DOCKERHUB_USERNAME` | `bautizar` |
| `DOCKERHUB_TOKEN` | The access token from step 1 |

### Deployment Workflow

1. **Push code to main** - GitHub Actions automatically builds and pushes new image

2. **Upload .env via FTP** (if changed) - Keep passwords secure, not in git:
   ```
   FTP to server → /path/to/eventstream-pulse/.env
   ```

3. **Pull and restart on server:**
   ```bash
   ssh user@monitor.eventstream.tech
   cd /path/to/eventstream-pulse

   docker pull bautizar/pulse:latest
   docker compose down
   docker compose up -d

   # If there are migrations:
   docker compose exec web python manage.py migrate
   ```

### Docker Image Tags

Each push creates two tags:
- `bautizar/pulse:latest` - Always the most recent build
- `bautizar/pulse:<sha>` - Specific commit SHA for rollback

### Rollback

To rollback to a previous version:
```bash
# Find the SHA you want
git log --oneline

# Pull specific version
docker pull bautizar/pulse:abc1234

# Update docker-compose.yml to use specific tag, then:
docker compose up -d
```

---

## Troubleshooting

### Common Issues

#### "Can't connect to database"

**Symptoms:** Web container shows "Waiting for database..." forever

**Solution:**
1. Check if db container is running: `docker compose ps`
2. Check db logs: `docker compose logs db`
3. Verify POSTGRES_* variables match in .env and docker-compose.yml

#### "Message not showing in API"

**Symptoms:** Created a message but API returns empty array

**Checklist:**
1. Is `is_active` checked? ✓
2. Is `start_date` in the past? (not future)
3. Is `end_date` null or in the future?
4. Is the correct app selected in "Target apps"?
5. Are you using the correct `app_id` in the API call?

**Debug:**
```bash
# Check message in database
docker compose exec web python manage.py shell -c "
from messages_app.models import PulseMessage
from django.utils import timezone
for m in PulseMessage.objects.all():
    print(f'{m.title}: active={m.is_active}, start={m.start_date}, now={timezone.now()}, is_currently_active={m.is_currently_active()}')
"
```

#### "Invalid token" error

**Symptoms:** API returns 403 Authentication failed

**Solution:**
- Check API_TOKEN in .env matches the token in your request
- Restart web container after changing .env: `docker compose restart web`

#### "Static files not loading"

**Symptoms:** Admin page looks broken, no CSS

**Solution:**
```bash
docker compose exec web python manage.py collectstatic --noinput
docker compose restart nginx
```

#### "Port 8000 already in use"

**Symptoms:** Container won't start

**Solution:**
```bash
# Find what's using the port
lsof -i :8000

# Kill the process or change the port in docker-compose.yml
```

### Getting Help

1. Check logs: `docker compose logs -f`
2. Check container status: `docker compose ps`
3. Enter container shell: `docker compose exec web bash`
4. Django shell: `docker compose exec web python manage.py shell`

---

## Project Structure

```
eventstream-pulse/
├── pulse_admin/                    # Django project
│   ├── pulse_admin/                # Project settings
│   │   ├── settings.py
│   │   ├── urls.py
│   │   ├── wsgi.py
│   │   └── asgi.py
│   ├── messages_app/               # Core messaging app
│   │   ├── models.py               # PulseMessage, TargetApp
│   │   ├── serializers.py          # DRF serializers
│   │   ├── views.py                # API endpoints
│   │   ├── admin.py                # Admin configuration
│   │   ├── urls.py                 # URL routing
│   │   └── management/commands/
│   │       └── seed_apps.py        # Seed target apps
│   ├── analytics/                  # Analytics app
│   │   ├── models.py               # MessageImpression, MessageTap
│   │   └── admin.py
│   └── manage.py
├── flutter/                        # Flutter integration files
│   └── lib/
│       ├── data/models/
│       ├── data/datasources/
│       ├── core/services/
│       └── presentation/
├── nginx/
│   └── nginx.conf                  # Nginx configuration
├── Dockerfile                      # Web container
├── docker-compose.yml              # Production setup
├── docker-compose.dev.yml          # Development setup
├── entrypoint.sh                   # Container entrypoint
├── requirements.txt                # Python dependencies
├── .env.example                    # Environment template
├── .gitignore
└── README.md                       # This file
```

---

## License

Proprietary - Eventstream

## Support

For issues, contact the development team.
