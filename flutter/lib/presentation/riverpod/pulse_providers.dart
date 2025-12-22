/// Pulse Riverpod Providers for state management
/// Copy this file to: lib/presentation/riverpod/pulse_providers.dart
///
/// IMPORTANT: Update the appId in pulseServiceProvider to match your app.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/pulse_service.dart';
import '../../data/models/pulse_message_model.dart';

/// Provider for the PulseService instance
/// TODO: Update appId to match your app (e.g., 'brighton', 'edinburgh')
final pulseServiceProvider = Provider<PulseService>((ref) {
  // Change this to your app's ID
  const appId = 'brighton'; // TODO: Update for each app
  return PulseService(appId: appId);
});

/// State notifier for pulse messages
class PulseMessagesNotifier extends StateNotifier<AsyncValue<List<PulseMessage>>> {
  final PulseService _pulseService;

  PulseMessagesNotifier(this._pulseService) : super(const AsyncValue.loading()) {
    loadMessages();
  }

  Future<void> loadMessages({bool forceRefresh = false}) async {
    try {
      state = const AsyncValue.loading();
      final messages = await _pulseService.fetchMessages(forceRefresh: forceRefresh);
      state = AsyncValue.data(messages);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> dismissMessage(int messageId) async {
    await _pulseService.dismissMessage(messageId);
    // Refresh the state to remove dismissed message
    final currentMessages = state.value ?? [];
    state = AsyncValue.data(
      currentMessages.where((m) => m.id != messageId).toList(),
    );
  }

  Future<void> recordImpression(int messageId) async {
    await _pulseService.recordImpression(messageId);
  }

  Future<void> recordTap(int messageId) async {
    await _pulseService.recordTap(messageId);
  }
}

/// Provider for the messages state notifier
final pulseMessagesProvider =
    StateNotifierProvider<PulseMessagesNotifier, AsyncValue<List<PulseMessage>>>(
        (ref) {
  final pulseService = ref.watch(pulseServiceProvider);
  return PulseMessagesNotifier(pulseService);
});

/// Provider for the next message to show
final nextPulseMessageProvider = Provider<PulseMessage?>((ref) {
  final messagesAsync = ref.watch(pulseMessagesProvider);
  return messagesAsync.when(
    data: (messages) {
      if (messages.isEmpty) return null;
      // Sort by priority and return first
      final sorted = [...messages]..sort((a, b) => a.priority.compareTo(b.priority));
      return sorted.first;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider to check if there are pending messages
final hasPendingMessagesProvider = Provider<bool>((ref) {
  final messagesAsync = ref.watch(pulseMessagesProvider);
  return messagesAsync.when(
    data: (messages) => messages.isNotEmpty,
    loading: () => false,
    error: (_, __) => false,
  );
});
