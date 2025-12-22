# Eventstream Pulse - Flutter Integration

This folder contains all the Flutter files needed to integrate Pulse in-app messaging into your city apps.

## Installation

### 1. Copy Files

Copy the following folders into your Flutter app's `lib/` directory:

```
lib/
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

In `pulse_providers.dart`, update the `appId` to match your city:

```dart
final pulseServiceProvider = Provider<PulseService>((ref) {
  const appId = 'brighton'; // Change to: edinburgh, manchester, cardiff, kilkenny, york
  return PulseService(appId: appId);
});
```

### 3. Dependencies

Ensure these packages are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  shared_preferences: ^2.5.2
  cached_network_image: ^3.4.1
  http: ^1.2.2
```

## Integration

### Show Messages on App Launch

In your main navigation or home screen widget, add the pulse check:

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

  // ... rest of widget
}
```

### Manual Trigger

You can also manually show messages:

```dart
// Get next message
final message = ref.read(nextPulseMessageProvider);
if (message != null) {
  PulseHandler.showMessage(context, message);
}

// Or show a specific type
showPulseModal(context, message);
showPulseBottomSheet(context, message);
showPulseFullScreen(context, message);
PulseBannerOverlay.show(context, message);
```

### Force Refresh

To force a refresh of messages from the server:

```dart
ref.read(pulseMessagesProvider.notifier).loadMessages(forceRefresh: true);
```

## Message Types

- **Modal**: Centered popup dialog requiring user acknowledgment
- **Banner**: Non-intrusive bar at top/bottom that slides in
- **Bottom Sheet**: Rich content sheet that slides up from bottom
- **Full Screen**: Full takeover for major announcements

## API Configuration

Update the API endpoint and token in `pulse_remote_datasource.dart`:

```dart
static const String _baseUrl = 'https://monitor.eventstream.tech/api';
static const String _apiToken = 'pulse_2025_centralized_messaging_token_prod';
```

## Debugging

Clear local cache for testing:

```dart
final service = ref.read(pulseServiceProvider);
await service.clearCache();
```
