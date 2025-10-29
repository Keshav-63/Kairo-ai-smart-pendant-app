// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For debugPrint
import 'local_storage_service.dart'; // Your local storage service

class ApiService {
  // Use localhost for simulators/emulators, replace with your actual backend IP/domain if needed
  static const String _baseUrl = 'http://localhost:8000'; // Assuming your Python backend runs on port 8000

  // Creates a new chat session and returns the session_id
  Future<String?> createChatSession() async {
    final storage = LocalStorageService.instance;
    final userId = storage.getUserId();
    final token = storage.getAuthToken(); // Assuming you need auth for this endpoint too

    if (userId == null || token == null) {
      debugPrint('[ApiService] User ID or Token not found for creating session.');
      throw Exception('User not logged in');
    }

    final url = Uri.parse('$_baseUrl/chats'); // Endpoint from app.py
    debugPrint('[ApiService] Creating chat session for user: $userId at $url');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Adjust if your auth differs
        },
        body: json.encode({'user_id': userId}),
      ).timeout(const Duration(seconds: 15));

      debugPrint('[ApiService] Create session response: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final sessionId = data['session_id'];
        debugPrint('[ApiService] Created session ID: $sessionId');
        return sessionId;
      } else {
        debugPrint('[ApiService] Failed to create session: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[ApiService] Error creating chat session: $e');
      return null;
    }
  }

  // Sends a query and returns the response map (answer, contexts, sources)
  Future<Map<String, dynamic>?> sendQuery({
    required String query,
    required String userId,
    required String sessionId,
  }) async {
    final storage = LocalStorageService.instance;
    final token = storage.getAuthToken();

    if (token == null) {
      debugPrint('[ApiService] Token not found for sending query.');
      throw Exception('User not logged in');
    }

    final url = Uri.parse('$_baseUrl/query'); // Endpoint from app.py
    debugPrint('[ApiService] Sending query to $url: User $userId, Session $sessionId, Query "$query"');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Adjust if your auth differs
        },
        body: json.encode({
          'query': query,
          'user_id': userId,
          'session_id': sessionId,
        }),
      ).timeout(const Duration(seconds: 60)); // Longer timeout for potentially complex queries

      debugPrint('[ApiService] Query response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('[ApiService] Query successful. Answer: ${data['answer']?.substring(0, 50)}...');
        return data;
      } else {
        debugPrint('[ApiService] Failed to send query: ${response.body}');
        return null; // Indicate failure
      }
    } catch (e) {
      debugPrint('[ApiService] Error sending query: $e');
      return null; // Indicate failure
    }
  }
}