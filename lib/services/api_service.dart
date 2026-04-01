// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For debugPrint
import 'local_storage_service.dart'; // Your local storage service

class ApiService {
  // Use localhost for simulators/emulators, replace with your actual backend IP/domain if needed
  static const String _baseUrl = 'https://keshavsuthar-kairo-api.hf.space'; // Assuming your Python backend runs on port 8000

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

  // Sends a query and streams assistant tokens using SSE.
  // Falls back to normal JSON response if backend does not stream.
  Future<Map<String, dynamic>?> streamQuery({
    required String query,
    required String userId,
    required String sessionId,
    required void Function(String token) onToken,
  }) async {
    final storage = LocalStorageService.instance;
    final token = storage.getAuthToken();

    if (token == null) {
      debugPrint('[ApiService] Token not found for streaming query.');
      throw Exception('User not logged in');
    }

    final url = Uri.parse('$_baseUrl/query');
    debugPrint('[ApiService] Streaming query to $url: User $userId, Session $sessionId');

    final client = http.Client();
    try {
      final request = http.Request('POST', url)
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'text/event-stream, application/json',
          'Cache-Control': 'no-cache',
        })
        ..body = json.encode({
          'query': query,
          'user_id': userId,
          'session_id': sessionId,
        });

      final response = await client.send(request).timeout(const Duration(seconds: 120));
      final status = response.statusCode;
      final contentType = response.headers['content-type'] ?? '';

      if (status != 200) {
        final body = await response.stream.bytesToString();
        debugPrint('[ApiService] Streaming query failed: $status $body');
        return null;
      }

      // Fallback path for non-streaming JSON responses.
      if (!contentType.contains('text/event-stream')) {
        final body = await response.stream.bytesToString();
        final data = json.decode(body);
        if (data is Map<String, dynamic>) {
          final answer = (data['answer'] ?? '').toString();
          if (answer.isNotEmpty) {
            onToken(answer);
          }
          return data;
        }
        return null;
      }

      final fullAnswer = StringBuffer();
      List<dynamic>? finalSources;
      String currentEvent = 'message';
      final dataLines = <String>[];

      void dispatchSseEvent() {
        if (dataLines.isEmpty) return;
        final payload = dataLines.join('\n').trim();
        dataLines.clear();

        if (payload.isEmpty) return;
        if (payload == '[DONE]') return;

        try {
          final decoded = json.decode(payload);
          if (decoded is Map<String, dynamic>) {
            if (decoded['sources'] is List) {
              finalSources = decoded['sources'] as List<dynamic>;
            }

            final tokenPiece = _extractTokenChunk(decoded);
            if (tokenPiece.isNotEmpty) {
              fullAnswer.write(tokenPiece);
              onToken(tokenPiece);
              return;
            }

            // Some backends emit a full "answer" in the final event.
            final answer = (decoded['answer'] ?? '').toString();
            if (answer.isNotEmpty && fullAnswer.isEmpty) {
              fullAnswer.write(answer);
              onToken(answer);
            }
            return;
          }

          // Non-map JSON payload; treat as token text.
          final asText = decoded.toString();
          if (asText.isNotEmpty) {
            fullAnswer.write(asText);
            onToken(asText);
          }
        } catch (_) {
          // Plain-text SSE data payload.
          if (payload.isNotEmpty) {
            fullAnswer.write(payload);
            onToken(payload);
          }
        } finally {
          currentEvent = 'message';
        }
      }

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.isEmpty) {
          dispatchSseEvent();
          continue;
        }

        if (line.startsWith('event:')) {
          currentEvent = line.substring(6).trim();
          continue;
        }

        if (line.startsWith('data:')) {
          dataLines.add(line.substring(5).trim());
          continue;
        }

        // Be permissive if backend sends raw lines.
        if (currentEvent == 'message' || currentEvent.isEmpty) {
          dataLines.add(line.trim());
        }
      }

      // Flush any trailing event data.
      dispatchSseEvent();

      return {
        'answer': fullAnswer.toString(),
        'sources': finalSources,
      };
    } catch (e) {
      debugPrint('[ApiService] Error streaming query: $e');
      return null;
    } finally {
      client.close();
    }
  }

  String _extractTokenChunk(Map<String, dynamic> event) {
    final candidates = [
      event['token'],
      event['delta'],
      event['content'],
      event['text'],
      event['chunk'],
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;
      final value = candidate.toString();
      if (value.isNotEmpty) return value;
    }

    return '';
  }
}