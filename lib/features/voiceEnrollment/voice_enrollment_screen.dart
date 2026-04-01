// lib/features/voiceEnrollment/voice_enrollment_screen.dart
//
// UI screen for Voice Enrollment.
// Mirrors the flow from src/pages/VoiceEnrollment.jsx in kairo-frontend:
//   1. User fills in speaker name + relationship
//   2. User records audio (start / stop)
//   3. User taps "Enroll" → POST to /enroll
//   4. Success / error feedback shown

import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/local_storage_service.dart';
import '../../constants/app_theme.dart';
import 'audio_recorder_service.dart';
import 'enrollment_api_service.dart';

// Relationship options — exact list from the web app (kairo-frontend)
const List<String> _kRelationships = [
  'self',
  'mom',
  'dad',
  'friend',
  'boss',
  'sibling',
  'partner',
  'child',
  'relative',
  'colleague',
  'other',
];

enum _EnrollStatus {
  idle,
  recording,
  recorded,
  uploading,
  success,
  error,
}

class VoiceEnrollmentScreen extends StatefulWidget {
  const VoiceEnrollmentScreen({super.key});

  @override
  State<VoiceEnrollmentScreen> createState() => _VoiceEnrollmentScreenState();
}

class _VoiceEnrollmentScreenState extends State<VoiceEnrollmentScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _recorderService = AudioRecorderService();
  final _apiService = EnrollmentApiService();

  String _selectedRelationship = 'friend';
  _EnrollStatus _status = _EnrollStatus.idle;
  String? _statusMessage;
  String? _recordedFilePath;

  // Recording timer
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // Enrollment history
  List<dynamic> _enrollments = [];
  bool _isLoadingEnrollments = true;

  // Pulse animation for the mic button while recording
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fetchEnrollments();
  }

  Future<void> _fetchEnrollments() async {
    setState(() => _isLoadingEnrollments = true);
    try {
      final storage = LocalStorageService.instance;
      final userId = storage.getUserId();
      if (userId == null) return;
      
      final url = Uri.parse('https://keshavsuthar-kairo-api.hf.space/enrollments/user/$userId');
      final resp = await http.get(url).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        if (mounted) {
          setState(() {
            _enrollments = data;
            _isLoadingEnrollments = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingEnrollments = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingEnrollments = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _recorderService.dispose();
    _pulseController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  // Recording logic
  // ──────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (_status == _EnrollStatus.recording) return;

    final started = await _recorderService.startRecording();
    if (!started) {
      setState(() {
        _status = _EnrollStatus.error;
        _statusMessage =
            'Microphone permission denied. Please grant permission in app settings.';
      });
      return;
    }

    _recordingSeconds = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordingSeconds++);
    });

    setState(() {
      _status = _EnrollStatus.recording;
      _statusMessage = null;
      _recordedFilePath = null;
    });
  }

  Future<void> _stopRecording() async {
    if (_status != _EnrollStatus.recording) return;

    _recordingTimer?.cancel();
    final path = await _recorderService.stopRecording();

    if (path == null) {
      setState(() {
        _status = _EnrollStatus.error;
        _statusMessage = 'Recording failed. Please try again.';
      });
      return;
    }

    setState(() {
      _recordedFilePath = path;
      _status = _EnrollStatus.recorded;
      _statusMessage = 'Recording complete! (${_formatDuration(_recordingSeconds)})';
    });
  }

  // ──────────────────────────────────────────────────────────
  // Enrollment (API call)
  // ──────────────────────────────────────────────────────────

  Future<void> _enroll() async {
    if (!_formKey.currentState!.validate()) return;
    if (_recordedFilePath == null) {
      setState(() {
        _status = _EnrollStatus.error;
        _statusMessage = 'Please record a voice sample first.';
      });
      return;
    }

    setState(() {
      _status = _EnrollStatus.uploading;
      _statusMessage = 'Uploading voice sample…';
    });

    final result = await _apiService.enrollVoice(
      personName: _nameController.text,
      relationship: _selectedRelationship,
      audioFilePath: _recordedFilePath!,
    );

    if (!mounted) return;

    setState(() {
      if (result.success) {
        _status = _EnrollStatus.success;
        _statusMessage = result.message;
        // Reset recording state so user can enroll another voice
        _recordedFilePath = null;
        _nameController.clear();
        _selectedRelationship = 'friend';
        _fetchEnrollments();
      } else {
        _status = _EnrollStatus.error;
        _statusMessage = result.message;
      }
    });
  }

  // ──────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _statusColor {
    switch (_status) {
      case _EnrollStatus.success:
        return AppTheme.successColor;
      case _EnrollStatus.error:
        return AppTheme.errorColor;
      case _EnrollStatus.uploading:
        return AppTheme.warningColor;
      case _EnrollStatus.recording:
        return Colors.redAccent;
      case _EnrollStatus.recorded:
        return AppTheme.secondaryAccent;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case _EnrollStatus.success:
        return Icons.check_circle_outline;
      case _EnrollStatus.error:
        return Icons.error_outline;
      case _EnrollStatus.uploading:
        return Icons.cloud_upload_outlined;
      case _EnrollStatus.recording:
        return Icons.fiber_manual_record;
      case _EnrollStatus.recorded:
        return Icons.audio_file_outlined;
      default:
        return Icons.mic_none;
    }
  }

  // ──────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isRecording = _status == _EnrollStatus.recording;
    final isUploading = _status == _EnrollStatus.uploading;
    final hasRecording = _recordedFilePath != null;
    final isSuccess = _status == _EnrollStatus.success;

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('Voice Enrollment'),
        backgroundColor: AppTheme.primaryBackground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header card ────────────────────────────────
              _buildHeaderCard(),
              const SizedBox(height: AppTheme.spacingL),

              // ── Speaker info form ──────────────────────────
              _buildSectionLabel('Speaker Information'),
              const SizedBox(height: AppTheme.spacingS),
              _buildNameField(),
              const SizedBox(height: AppTheme.spacingM),
              _buildRelationshipDropdown(),
              const SizedBox(height: AppTheme.spacingXL),

              // ── Mic recording UI ───────────────────────────
              _buildSectionLabel('Voice Sample'),
              const SizedBox(height: AppTheme.spacingM),
              _buildMicButton(isRecording),
              const SizedBox(height: AppTheme.spacingS),
              _buildRecordingHint(isRecording),
              const SizedBox(height: AppTheme.spacingXL),

              // ── Status feedback ────────────────────────────
              if (_statusMessage != null) ...[
                _buildStatusCard(),
                const SizedBox(height: AppTheme.spacingL),
              ],

              // ── Enroll button ──────────────────────────────
              if (!isSuccess)
                _buildEnrollButton(
                  enabled: hasRecording && !isUploading && !isRecording,
                  isUploading: isUploading,
                ),

              // ── Enroll another button (after success) ──────
              if (isSuccess) ...[
                const SizedBox(height: AppTheme.spacingM),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Enroll Another Voice'),
                  style: AppTheme.secondaryButtonStyle,
                  onPressed: () {
                    setState(() {
                      _status = _EnrollStatus.idle;
                      _statusMessage = null;
                    });
                  },
                ),
              ],

              const SizedBox(height: AppTheme.spacingXL),
              
              // ── Enrollment History ────────────────────────
              _buildSectionLabel('Enrollment History'),
              const SizedBox(height: AppTheme.spacingM),
              _buildEnrollmentHistory(),

              const SizedBox(height: AppTheme.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Sub-widgets
  // ──────────────────────────────────────────────────────────

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Row(
        children: [
          const Icon(Icons.record_voice_over, color: Colors.white, size: 36),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Enrollment',
                  style: AppTheme.headingSmall.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Register a voice so Kairo can recognize who is speaking.',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: AppTheme.caption.copyWith(
        letterSpacing: 1.2,
        color: AppTheme.primaryAccent,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: AppTheme.bodyLarge,
      decoration: AppTheme.inputDecoration(
        hintText: 'e.g. Mom, John, Boss',
        labelText: 'Speaker Name',
        prefixIcon: const Icon(Icons.person_outline, color: AppTheme.textTertiary),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Please enter a name.';
        return null;
      },
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildRelationshipDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRelationship,
      decoration: AppTheme.inputDecoration(
        labelText: 'Relationship',
        prefixIcon: const Icon(Icons.people_outline, color: AppTheme.textTertiary),
      ),
      dropdownColor: AppTheme.cardBackground,
      style: AppTheme.bodyLarge,
      items: _kRelationships.map((r) {
        return DropdownMenuItem(
          value: r,
          child: Text(
            // Capitalize first letter for display
            r[0].toUpperCase() + r.substring(1),
            style: AppTheme.bodyLarge,
          ),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _selectedRelationship = v);
      },
      validator: (v) => v == null || v.isEmpty ? 'Please select a relationship.' : null,
    );
  }

  Widget _buildMicButton(bool isRecording) {
    return Center(
      child: GestureDetector(
        onTap: isRecording ? _stopRecording : _startRecording,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final scale = isRecording ? _pulseAnimation.value : 1.0;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isRecording
                      ? const LinearGradient(
                          colors: [Colors.redAccent, Color(0xFFFF6B6B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: (isRecording ? Colors.red : AppTheme.primaryAccent)
                          .withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  isRecording ? Icons.stop_rounded : Icons.mic,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecordingHint(bool isRecording) {
    String hint;
    if (isRecording) {
      hint = 'Recording… ${_formatDuration(_recordingSeconds)}  •  Tap to stop';
    } else if (_recordedFilePath != null) {
      hint = 'Sample recorded ✓  Tap mic to re-record';
    } else {
      hint = 'Tap the mic to start recording';
    }

    return Center(
      child: Text(
        hint,
        style: AppTheme.bodySmall.copyWith(
          color: isRecording ? Colors.redAccent : AppTheme.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatusCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          _status == _EnrollStatus.uploading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _statusColor,
                  ),
                )
              : Icon(_statusIcon, color: _statusColor, size: 20),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              _statusMessage ?? '',
              style: AppTheme.bodyMedium.copyWith(color: _statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollButton({required bool enabled, required bool isUploading}) {
    return ElevatedButton.icon(
      icon: isUploading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.cloud_upload_outlined),
      label: Text(isUploading ? 'Enrolling…' : 'Enroll Voice'),
      style: AppTheme.primaryButtonStyle.copyWith(
        minimumSize: const WidgetStatePropertyAll(
          Size(double.infinity, 52),
        ),
        backgroundColor: WidgetStatePropertyAll(
          enabled ? AppTheme.primaryAccent : AppTheme.surfaceColor,
        ),
        foregroundColor: WidgetStatePropertyAll(
          enabled ? Colors.white : AppTheme.textTertiary,
        ),
      ),
      onPressed: enabled ? _enroll : null,
    );
  }

  Widget _buildEnrollmentHistory() {
    if (_isLoadingEnrollments) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    }
    if (_enrollments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16), 
          child: Text('No voices enrolled yet.', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary))
        )
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _enrollments.length,
      itemBuilder: (context, index) {
        final item = _enrollments[index];
        final name = item['personName'] ?? 'Unknown';
        final relationship = item['relationship'] ?? 'Unknown';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const Icon(Icons.person, color: AppTheme.primaryAccent, size: 28),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(relationship, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              if (item['has_embedding'] == true)
                const Icon(Icons.check_circle, color: AppTheme.successColor, size: 20)
            ],
          ),
        );
      },
    );
  }
}
