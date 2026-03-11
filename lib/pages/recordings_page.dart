import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import '../services/local_storage_service.dart';
import '../constants/app_theme.dart';
import 'package:intl/intl.dart';

class RecordingsPage extends StatefulWidget {
  const RecordingsPage({super.key});

  @override
  State<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  bool _isLoading = true;
  String? _error;
  List<Recording> _recordings = [];
  List<Recording> _filteredRecordings = [];
  String _searchTerm = '';
  String _selectedFilter = 'all';
  String? _currentlyPlaying;
  Map<String, double> _playbackProgress = {};
  final Map<String, AudioPlayer> _audioPlayers = {};

  @override
  void initState() {
    super.initState();
    _fetchRecordings();
  }

  @override
  void dispose() {
    // Dispose all audio players
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchRecordings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storage = LocalStorageService.instance;
      final userId = storage.getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      const baseUrl = 'https://keshavsuthar-kairo-api.hf.space';
      final url = Uri.parse('$baseUrl/recordings/$userId');

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _recordings = data.map((json) => Recording.fromJson(json)).toList();
          _filteredRecordings = _recordings;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load recordings');
      }
    } catch (e) {
      setState(() {
        _error = 'Could not load your recordings. Please try again.';
        _isLoading = false;
      });
      debugPrint('[RecordingsPage] Error fetching recordings: $e');
    }
  }

  void _filterRecordings() {
    setState(() {
      _filteredRecordings = _recordings.where((recording) {
        final matchesSearch = _searchTerm.isEmpty ||
            recording.title.toLowerCase().contains(_searchTerm.toLowerCase()) ||
            recording.speaker.toLowerCase().contains(_searchTerm.toLowerCase());

        final matchesFilter = _selectedFilter == 'all' ||
            recording.category == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _togglePlayback(Recording recording) async {
    try {
      final storage = LocalStorageService.instance;
      final userId = storage.getUserId();

      if (userId == null) return;

      // Pause any currently playing audio
      if (_currentlyPlaying != null && _currentlyPlaying != recording.id) {
        await _audioPlayers[_currentlyPlaying]?.pause();
      }

      // If this recording is already playing, pause it
      if (_currentlyPlaying == recording.id) {
        await _audioPlayers[recording.id]?.pause();
        setState(() {
          _currentlyPlaying = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playback paused'),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }

      // Create audio URL
      const baseUrl = 'https://keshavsuthar-kairo-api.hf.space';
      final audioUrl = '$baseUrl/audio/${recording.sessionId}?user_id=$userId';

      // Create audio player if it doesn't exist
      if (!_audioPlayers.containsKey(recording.id)) {
        _audioPlayers[recording.id] = AudioPlayer();

        // Set up listeners
        _audioPlayers[recording.id]!.onPositionChanged.listen((position) {
          if (mounted) {
            final duration = _audioPlayers[recording.id]!.getDuration();
            duration.then((d) {
              if (d != null && d.inMilliseconds > 0) {
                setState(() {
                  _playbackProgress[recording.id] =
                      (position.inMilliseconds / d.inMilliseconds) * 100;
                });
              }
            });
          }
        });

        _audioPlayers[recording.id]!.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _currentlyPlaying = null;
              _playbackProgress[recording.id] = 0;
            });
          }
        });
      }

      // Play the audio
      setState(() {
        _currentlyPlaying = recording.id;
        _playbackProgress[recording.id] = 0;
      });

      await _audioPlayers[recording.id]!.play(UrlSource(audioUrl));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playing: ${recording.title}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to play audio'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('[RecordingsPage] Error playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: Text('Recordings', style: AppTheme.headingMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRecordings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _buildRecordingsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage and play your recorded conversations',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_filteredRecordings.length} recordings',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
                _filterRecordings();
              },
              decoration: InputDecoration(
                hintText: 'Search recordings...',
                prefixIcon: const Icon(Icons.search, color: Colors.white60),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                dropdownColor: Colors.grey[850],
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'work', child: Text('Work')),
                  DropdownMenuItem(value: 'business', child: Text('Business')),
                  DropdownMenuItem(value: 'personal', child: Text('Personal')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFilter = value;
                    });
                    _filterRecordings();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.indigoAccent),
          SizedBox(height: 16),
          Text(
            'Loading recordings...',
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchRecordings,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingsList() {
    if (_filteredRecordings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_none,
              size: 80,
              color: Colors.white30,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Recordings Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchTerm.isNotEmpty || _selectedFilter != 'all'
                  ? 'No recordings match your search criteria'
                  : 'Your recordings will appear here',
              style: const TextStyle(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRecordings,
      color: Colors.indigoAccent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredRecordings.length,
        itemBuilder: (context, index) {
          return _buildRecordingCard(_filteredRecordings[index]);
        },
      ),
    );
  }

  Widget _buildRecordingCard(Recording recording) {
    final isPlaying = _currentlyPlaying == recording.id;
    final progress = _playbackProgress[recording.id] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying
              ? Colors.indigoAccent.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        recording.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(recording.category),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        recording.category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      recording.speaker,
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      recording.duration,
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today, size: 16, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(recording.date),
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Waveform visualization with progress
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      50,
                      (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: (index / 50 * 100) <= progress && isPlaying
                                ? Colors.indigoAccent
                                : Colors.white30,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          height: (index % 5 + 1) * 8.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _togglePlayback(recording),
                      icon: Icon(
                        isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        size: 48,
                        color: Colors.indigoAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPlaying ? 'Playing...' : 'Ready to play',
                      style: const TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        // Download functionality placeholder
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Downloading ${recording.title}')),
                        );
                      },
                      icon: const Icon(Icons.download, color: Colors.white60),
                    ),
                    IconButton(
                      onPressed: () {
                        // Delete functionality placeholder
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Recording'),
                            content: const Text('Are you sure you want to delete this recording?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Recording deleted')),
                                  );
                                },
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (recording.transcript.isNotEmpty) ...[
            const Divider(color: Colors.white10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '"${recording.transcript}"',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Colors.blueAccent.withOpacity(0.3);
      case 'business':
        return Colors.greenAccent.withOpacity(0.3);
      case 'personal':
        return Colors.purpleAccent.withOpacity(0.3);
      default:
        return Colors.grey.withOpacity(0.3);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).ceil()} weeks ago';
    return DateFormat('MMM dd, yyyy').format(date);
  }
}

// Recording model
class Recording {
  final String id;
  final String sessionId;
  final String title;
  final String speaker;
  final String duration;
  final String size;
  final String quality;
  final String category;
  final DateTime date;
  final double durationSeconds;
  final String transcript;

  Recording({
    required this.id,
    required this.sessionId,
    required this.title,
    required this.speaker,
    required this.duration,
    required this.size,
    required this.quality,
    required this.category,
    required this.date,
    required this.durationSeconds,
    required this.transcript,
  });

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'] ?? json['_id']?['\$oid'] ?? '',
      sessionId: json['sessionId'] ?? json['session_id'] ?? '',
      title: json['title'] ?? 'Untitled Recording',
      speaker: json['speaker'] ?? 'Unknown',
      duration: json['duration'] ?? '00:00',
      size: json['size'] ?? '0 MB',
      quality: json['quality'] ?? 'medium',
      category: json['category'] ?? 'personal',
      date: json['date'] != null
          ? DateTime.tryParse(json['date']) ?? DateTime.now()
          : json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
              : DateTime.now(),
      durationSeconds: (json['durationSeconds'] ?? 0).toDouble(),
      transcript: json['transcript'] ?? json['summary'] ?? '',
    );
  }
}
