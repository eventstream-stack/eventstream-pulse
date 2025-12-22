/// Pulse Service - orchestrates message fetching, caching, and dismissals
/// Copy this file to: lib/core/services/pulse_service.dart

import 'package:flutter/foundation.dart';
import '../../data/datasources/remote/pulse_remote_datasource.dart';
import '../../data/datasources/local/pulse_local_storage.dart';
import '../../data/models/pulse_message_model.dart';

class PulseService {
  final PulseRemoteDataSource _remoteDataSource;
  final PulseLocalStorage _localStorage;

  List<PulseMessage> _pendingMessages = [];
  bool _hasCheckedMessages = false;

  PulseService({required String appId})
      : _remoteDataSource = PulseRemoteDataSource(appId: appId),
        _localStorage = PulseLocalStorage();

  /// Fetch active messages from API or cache
  Future<List<PulseMessage>> fetchMessages({bool forceRefresh = false}) async {
    try {
      // Check cache first
      if (!forceRefresh) {
        final cached = await _localStorage.getCachedMessages();
        if (cached != null) {
          _pendingMessages = await _filterDismissedMessages(cached);
          return _pendingMessages;
        }
      }

      // Fetch from API
      final messages = await _remoteDataSource.getActiveMessages();

      // Cache the results
      await _localStorage.cacheMessages(messages);

      // Filter out dismissed messages
      _pendingMessages = await _filterDismissedMessages(messages);
      _hasCheckedMessages = true;

      return _pendingMessages;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching pulse messages: $e');
      }
      // Return cached messages on error
      final cached = await _localStorage.getCachedMessages();
      if (cached != null) {
        _pendingMessages = await _filterDismissedMessages(cached);
        return _pendingMessages;
      }
      return [];
    }
  }

  /// Filter out messages that have been dismissed locally
  Future<List<PulseMessage>> _filterDismissedMessages(
      List<PulseMessage> messages) async {
    final dismissedIds = await _localStorage.getDismissedMessageIds();
    return messages.where((m) => !dismissedIds.contains(m.id)).toList();
  }

  /// Get the next message to display (highest priority first)
  PulseMessage? getNextMessage() {
    if (_pendingMessages.isEmpty) return null;

    // Sort by priority (lower number = higher priority)
    _pendingMessages.sort((a, b) => a.priority.compareTo(b.priority));
    return _pendingMessages.first;
  }

  /// Dismiss a message locally
  Future<void> dismissMessage(int messageId) async {
    await _localStorage.dismissMessage(messageId);
    _pendingMessages.removeWhere((m) => m.id == messageId);
  }

  /// Record that a message was shown
  Future<void> recordImpression(int messageId) async {
    await _remoteDataSource.recordImpression(messageId);
  }

  /// Record that a message CTA was tapped
  Future<void> recordTap(int messageId) async {
    await _remoteDataSource.recordTap(messageId);
  }

  /// Check if there are pending messages
  bool get hasPendingMessages => _pendingMessages.isNotEmpty;

  /// Get all pending messages
  List<PulseMessage> get pendingMessages => List.unmodifiable(_pendingMessages);

  /// Check if messages have been checked
  bool get hasCheckedMessages => _hasCheckedMessages;

  /// Clear local cache (for debugging)
  Future<void> clearCache() async {
    await _localStorage.clearCache();
    await _localStorage.clearDismissedMessages();
    _pendingMessages = [];
    _hasCheckedMessages = false;
  }
}
