# Flutter Integration Guide

This guide explains how to integrate Pulse in-app messaging into your Flutter city apps.

## Installation

### 1. Copy Files

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

### 2. Update App ID

In `pulse_providers.dart`, change the app ID to match your city:

```dart
final pulseServiceProvider = Provider<PulseService>((ref) {
  const appId = 'brighton'; // Change to: edinburgh, manchester, cardiff, kilkenny, york
  return PulseService(appId: appId);
});
```

### 3. Add Dependencies

Ensure these packages are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  shared_preferences: ^2.5.2
  cached_network_image: ^3.4.1
  http: ^1.2.2
```

### 4. Configure API

Update the API endpoint and token in `pulse_remote_datasource.dart`:

```dart
static const String _baseUrl = 'https://monitor.eventstream.tech/api';
static const String _apiToken = 'your_production_token';
```

---

## Integration

### Show Messages on App Launch

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

### Manual Trigger

You can manually show messages anywhere in your app:

```dart
// Get and show next message
final message = ref.read(nextPulseMessageProvider);
if (message != null) {
  PulseHandler.showMessage(context, message);
}

// Or show specific types directly
showPulseModal(context, message);
showPulseBottomSheet(context, message);
showPulseFullScreen(context, message);
PulseBannerOverlay.show(context, message);
```

### Force Refresh Messages

To force a refresh of messages from the server:

```dart
ref.read(pulseMessagesProvider.notifier).loadMessages(forceRefresh: true);
```

### Clear Local Cache

For testing purposes, clear the local cache:

```dart
final service = ref.read(pulseServiceProvider);
await service.clearCache();
```

---

## Message Types

| Type | Widget | Description |
|------|--------|-------------|
| `modal` | `pulse_modal.dart` | Centered popup dialog requiring acknowledgment |
| `banner` | `pulse_banner.dart` | Non-intrusive bar at top/bottom that slides in |
| `bottom_sheet` | `pulse_bottom_sheet.dart` | Rich content sheet that slides up from bottom |
| `full_screen` | `pulse_full_screen.dart` | Full takeover for major announcements |

---

## Handling CTA Actions

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

## App IDs Reference

| App ID | City |
|--------|------|
| `brighton` | Brighton |
| `edinburgh` | Edinburgh |
| `manchester` | Manchester |
| `cardiff` | Cardiff |
| `kilkenny` | Kilkenny |
| `york` | York |
