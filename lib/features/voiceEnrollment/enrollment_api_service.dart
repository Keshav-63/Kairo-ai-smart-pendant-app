// lib/features/voiceEnrollment/enrollment_api_service.dart
//
// Replicates the web app's `enrollVoice()` function from src/api/axios.js.
// POST https://keshavsuthar-kairo-api.hf.space/enroll
//   Content-Type: multipart/form-data
//   Authorization: Bearer <token>
//   Fields: user_id, person_name, relationship, voice_sample

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../services/local_storage_service.dart';

/// Result of a voice enrollment API call.
class EnrollmentResult {
  final bool success;
  final String message;

  const EnrollmentResult({required this.success, required this.message});
}

class EnrollmentApiService {
  static const String _baseUrl = 'https://keshavsuthar-kairo-api.hf.space';

  /// Enrolls a voice by posting to /enroll.
  ///
  /// [personName]   — speaker's name (will be lowercased + trimmed, matching web)
  /// [relationship] — relationship string (will be lowercased, matching web)
  /// [audioFilePath] — local path to the recorded audio file
  Future<EnrollmentResult> enrollVoice({
    required String personName,
    required String relationship,
    required String audioFilePath,
  }) async {
    final storage = LocalStorageService.instance;
    final userId = storage.getUserId();
    final token = storage.getAuthToken();

    if (userId == null || token == null) {
      debugPrint('[EnrollmentApiService] User not logged in — userId or token is null.');
      return const EnrollmentResult(
        success: false,
        message: 'You must be logged in to enroll a voice.',
      );
    }

    final file = File(audioFilePath);
    if (!file.existsSync()) {
      debugPrint('[EnrollmentApiService] Audio file not found: $audioFilePath');
      return const EnrollmentResult(
        success: false,
        message: 'Audio file not found. Please record again.',
      );
    }

    final url = Uri.parse('$_baseUrl/enroll');

    // Build request — field names must match the web FormData exactly.
    final request = http.MultipartRequest('POST', url);

    // Auth header — same Bearer pattern used in api_service.dart
    request.headers['Authorization'] = 'Bearer $token';

    // FormData fields — mirroring web: person_name.trim().toLowerCase()
    request.fields['user_id'] = userId;
    request.fields['person_name'] = personName.trim().toLowerCase();
    request.fields['relationship'] = relationship.trim().toLowerCase();

    // Audio file field name must match web: 'voice_sample'
    // File naming convention from web: `${speakerName}_enrollment.webm`
    final fileName =
        '${personName.trim().toLowerCase().replaceAll(' ', '_')}_enrollment.m4a';

    request.files.add(
      await http.MultipartFile.fromPath(
        'voice_sample', // exact field name from web FormData
        audioFilePath,
        filename: fileName,
      ),
    );

    debugPrint('[EnrollmentApiService] POST $url');
    debugPrint('[EnrollmentApiService] user_id=$userId, person_name=${personName.trim().toLowerCase()}, relationship=${relationship.toLowerCase()}, file=$fileName');

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[EnrollmentApiService] Response status: ${response.statusCode}');
      debugPrint('[EnrollmentApiService] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202) {
        // Web app reads response.data.message on success
        String msg = 'Voice enrolled successfully!';
        try {
          final body = response.body;
          // Simple extraction — avoid dart:convert for safety
          if (body.contains('"message"')) {
            final start = body.indexOf('"message"') + 11;
            final trimmed = body.substring(start).trim();
            if (trimmed.startsWith('"')) {
              final end = trimmed.indexOf('"', 1);
              if (end != -1) msg = trimmed.substring(1, end);
            }
          }
        } catch (_) {
          // Keep default message
        }
        return EnrollmentResult(success: true, message: msg);
      } else {
        // Web app reads error field on failure
        String errMsg = 'Enrollment failed (${response.statusCode}).';
        try {
          final body = response.body;
          if (body.contains('"error"')) {
            final start = body.indexOf('"error"') + 9;
            final trimmed = body.substring(start).trim();
            if (trimmed.startsWith('"')) {
              final end = trimmed.indexOf('"', 1);
              if (end != -1) errMsg = trimmed.substring(1, end);
            }
          }
        } catch (_) {
          // Keep default error
        }
        return EnrollmentResult(success: false, message: errMsg);
      }
    } on SocketException {
      return const EnrollmentResult(
        success: false,
        message: 'No internet connection.',
      );
    } catch (e) {
      debugPrint('[EnrollmentApiService] Error: $e');
      return EnrollmentResult(
        success: false,
        message: 'An unexpected error occurred: $e',
      );
    }
  }
}
