/// Pulse Local Storage for dismissal tracking and caching
/// Copy this file to: lib/data/datasources/local/pulse_local_storage.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/pulse_message_model.dart';

class PulseLocalStorage {
  static const String _dismissedMessagesKey = 'pulse_dismissed_messages';
  static const String _cachedMessagesKey = 'pulse_cached_messages';
  static const String _cacheTimestampKey = 'pulse_cache_timestamp';
  static const Duration _cacheTTL = Duration(minutes: 5);

  // Singleton pattern
  static final PulseLocalStorage _instance = PulseLocalStorage._internal();
  factory PulseLocalStorage() => _instance;
  PulseLocalStorage._internal();

  /// Get list of dismissed message IDs
  Future<Set<int>> getDismissedMessageIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? dismissed = prefs.getStringList(_dismissedMessagesKey);
    if (dismissed == null) return {};
    return dismissed.map((id) => int.parse(id)).toSet();
  }

  /// Mark a message as dismissed
  Future<void> dismissMessage(int messageId) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = await getDismissedMessageIds();
    dismissed.add(messageId);
    await prefs.setStringList(
      _dismissedMessagesKey,
      dismissed.map((id) => id.toString()).toList(),
    );
  }

  /// Check if a message has been dismissed
  Future<bool> isMessageDismissed(int messageId) async {
    final dismissed = await getDismissedMessageIds();
    return dismissed.contains(messageId);
  }

  /// Clear all dismissed messages (useful for debugging)
  Future<void> clearDismissedMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dismissedMessagesKey);
  }

  /// Cache messages locally
  Future<void> cacheMessages(List<PulseMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = messages.map((m) => m.toJson()).toList();
    await prefs.setString(_cachedMessagesKey, json.encode(jsonList));
    await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached messages if not expired
  Future<List<PulseMessage>?> getCachedMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_cachedMessagesKey);
    final int? timestamp = prefs.getInt(_cacheTimestampKey);

    if (jsonString == null || timestamp == null) return null;

    final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final isExpired = DateTime.now().difference(cachedTime) > _cacheTTL;

    if (isExpired) {
      await clearCache();
      return null;
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => PulseMessage.fromJson(j)).toList();
    } catch (e) {
      await clearCache();
      return null;
    }
  }

  /// Check if cache is valid
  Future<bool> isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final int? timestamp = prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return false;

    final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cachedTime) <= _cacheTTL;
  }

  /// Clear message cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedMessagesKey);
    await prefs.remove(_cacheTimestampKey);
  }
}
