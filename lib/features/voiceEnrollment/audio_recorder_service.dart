// lib/features/voiceEnrollment/audio_recorder_service.dart
//
// Wraps the `record` package to provide a simple start/stop recording API.
// Returns the path to the recorded audio file (m4a/AAC on mobile).

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  String? _currentFilePath;

  bool get isRecording => _isRecording;
  String? get lastFilePath => _currentFilePath;

  /// Requests microphone permission and starts recording.
  /// Returns true if recording started successfully.
  Future<bool> startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('[AudioRecorderService] Microphone permission denied.');
        return false;
      }

      // Save to a temp directory with a timestamped name
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/kairo_enrollment_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc, // AAC-LC → .m4a container
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1, // Mono is sufficient for voice
        ),
        path: filePath,
      );

      _isRecording = true;
      _currentFilePath = filePath;
      debugPrint('[AudioRecorderService] Recording started → $filePath');
      return true;
    } catch (e) {
      debugPrint('[AudioRecorderService] Error starting recording: $e');
      return false;
    }
  }

  /// Stops the recording and returns the path to the recorded file.
  /// Returns null if recording was not active or an error occurred.
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        debugPrint('[AudioRecorderService] stopRecording called but not recording.');
        return null;
      }

      final path = await _recorder.stop();
      _isRecording = false;
      debugPrint('[AudioRecorderService] Recording stopped. File: $path');

      if (path == null) {
        debugPrint('[AudioRecorderService] Recorder returned null path.');
        return null;
      }

      final file = File(path);
      if (!file.existsSync()) {
        debugPrint('[AudioRecorderService] Recorded file does not exist at: $path');
        return null;
      }

      _currentFilePath = path;
      return path;
    } catch (e) {
      debugPrint('[AudioRecorderService] Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancels any active recording and cleans up.
  Future<void> cancel() async {
    try {
      await _recorder.cancel();
      _isRecording = false;
      debugPrint('[AudioRecorderService] Recording cancelled.');
    } catch (e) {
      debugPrint('[AudioRecorderService] Error cancelling recording: $e');
    }
  }

  /// Releases native resources. Call in dispose().
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
