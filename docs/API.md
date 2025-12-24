# API Documentation

**Base URL:** `https://monitor.eventstream.tech/api`

## Authentication

All API requests require a `token` query parameter:

```
?token=your_api_token
```

The token is validated against the `API_TOKEN` environment variable.

---

## Endpoints

### GET /api/messages/

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
    "background_color": "#FFFFFF",
    "title_color": "#1a1a1a",
    "body_color": "#666666",
    "button_color": "#007AFF",
    "button_text_color": "#FFFFFF",
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
| `background_color` | string | Message background color (hex) |
| `title_color` | string | Title text color (hex) |
| `body_color` | string | Body text color (hex) |
| `button_color` | string | CTA button background color (hex) |
| `button_text_color` | string | CTA button text color (hex) |
| `target_app_ids` | array | List of targeted app IDs |
| `start_date` | datetime | When message becomes active |
| `end_date` | datetime | When message expires (null = never) |
| `is_currently_active` | boolean | Is message active right now? |

---

### POST /api/messages/{id}/impression/

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

### POST /api/messages/{id}/tap/

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

## Message Types

| Type | Description |
|------|-------------|
| `modal` | Centered popup dialog (blocks interaction) |
| `banner` | Non-intrusive bar at top/bottom |
| `bottom_sheet` | Rich content sheet that slides up from bottom |
| `full_screen` | Full takeover for major announcements |

## Priority Levels

| Priority | Description |
|----------|-------------|
| 1 | Critical - Show immediately |
| 2 | High - Show soon |
| 3 | Normal - Standard queue |
| 4 | Low - Background |

## Target App IDs

| App ID | App Name |
|--------|----------|
| `brighton` | The Brighton App |
| `edinburgh` | The Edinburgh App |
| `manchester` | The Manchester App |
| `cardiff` | The Cardiff App |
| `kilkenny` | The Kilkenny App |
| `york` | The York App |

---

## Error Responses

**400 Bad Request** - Missing required parameter:
```json
{"error": "app_id query parameter is required"}
```

**403 Forbidden** - Invalid token:
```json
{"detail": "Authentication failed. Invalid token."}
```

**404 Not Found** - Message doesn't exist:
```json
{"error": "Message not found"}
```
