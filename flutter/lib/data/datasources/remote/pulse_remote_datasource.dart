/// Pulse Remote Datasource for API communication
/// Copy this file to: lib/data/datasources/remote/pulse_remote_datasource.dart
///
/// IMPORTANT: Update _baseUrl and _apiToken with your actual values,
/// or inject them from your app's config.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/pulse_message_model.dart';

class PulseRemoteDataSource {
  // TODO: Update these values or inject from config
  static const String _baseUrl = 'https://monitor.eventstream.tech/api';
  static const String _apiToken = 'pulse_2025_centralized_messaging_token_prod';

  final String appId; // e.g., "brighton", "edinburgh"

  PulseRemoteDataSource({required this.appId});

  /// Fetch active messages from the API
  Future<List<PulseMessage>> getActiveMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/messages/?app_id=$appId&token=$_apiToken'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => PulseMessage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load pulse messages: $e');
    }
  }

  /// Record that a message was displayed
  Future<void> recordImpression(int messageId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/messages/$messageId/impression/?app_id=$appId&token=$_apiToken'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Silently fail - analytics shouldn't break the app
      print('Failed to record impression: $e');
    }
  }

  /// Record that a message CTA was tapped
  Future<void> recordTap(int messageId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/messages/$messageId/tap/?app_id=$appId&token=$_apiToken'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Silently fail - analytics shouldn't break the app
      print('Failed to record tap: $e');
    }
  }
}
