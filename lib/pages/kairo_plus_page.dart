import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/local_storage_service.dart';
import '../constants/app_theme.dart';
import 'package:intl/intl.dart';

class KairoPlusPage extends StatefulWidget {
  const KairoPlusPage({super.key});

  @override
  State<KairoPlusPage> createState() => _KairoPlusPageState();
}

class _KairoPlusPageState extends State<KairoPlusPage> {
  bool _isLoading = true;
  String? _error;
  List<AnalyticsSummary> _summaryData = [];
  DailyAnalytics? _selectedDateData;
  bool _isSidebarMinimized = false;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
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

      // Fetch analytics summary
      const baseUrl = 'https://keshavsuthar-kairo-api.hf.space';
      final url = Uri.parse('$baseUrl/analytics/user/$userId/summary');

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final summaries = data.map((json) => AnalyticsSummary.fromJson(json)).toList();

        setState(() {
          _summaryData = summaries;
          _isLoading = false;
        });

        // Load the most recent day's details
        if (summaries.isNotEmpty) {
          await _fetchDailyAnalytics(summaries[0].date);
        }
      } else {
        throw Exception('Failed to load analytics');
      }
    } catch (e) {
      setState(() {
        _error = 'Could not load your Kairo Plus analytics.';
        _isLoading = false;
      });
      debugPrint('[KairoPlusPage] Error fetching analytics: $e');
    }
  }

  Future<void> _fetchDailyAnalytics(String dateStr) async {
    try {
      final storage = LocalStorageService.instance;
      final userId = storage.getUserId();

      if (userId == null) return;

      const baseUrl = 'https://keshavsuthar-kairo-api.hf.space';
      final url = Uri.parse('$baseUrl/analytics/user/$userId/$dateStr');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _selectedDateData = DailyAnalytics.fromJson(data);
          _isSidebarMinimized = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load details for $dateStr')),
      );
      debugPrint('[KairoPlusPage] Error fetching daily analytics: $e');
    }
  }

  String _formatSeconds(double seconds) {
    if (seconds < 60) return '${seconds.round()}s';
    final minutes = (seconds / 60).floor();
    final hours = (minutes / 60).floor();
    if (hours > 0) {
      return '${hours}h ${minutes % 60}m';
    }
    return '${minutes}m ${(seconds % 60).round()}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: Text('Kairo Plus Analytics', style: AppTheme.headingMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSidebarMinimized ? Icons.menu_open : Icons.menu),
            onPressed: () {
              setState(() {
                _isSidebarMinimized = !_isSidebarMinimized;
              });
            },
            tooltip: _isSidebarMinimized ? 'Expand Sidebar' : 'Minimize Sidebar',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _summaryData.isEmpty
                  ? _buildEmptyState()
                  : _buildAnalyticsDashboard(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.successColor),
          SizedBox(height: 16),
          Text(
            'Loading your analytics...',
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
              onPressed: _fetchAnalytics,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.white30,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Analytics Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Once your sessions are processed, your Kairo Plus dashboard will appear here.',
              style: TextStyle(color: Colors.white60, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsDashboard() {
    return Row(
      children: [
        // Left sidebar - Date selector
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _isSidebarMinimized ? 70 : 280,
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            border: Border(
              right: BorderSide(color: AppTheme.dividerColor),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isSidebarMinimized
                    ? const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 24,
                      )
                    : const Text(
                        'Your Activity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _summaryData.length,
                  itemBuilder: (context, index) {
                    final day = _summaryData[index];
                    final isSelected = _selectedDateData?.date == day.date;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.successColor.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isSidebarMinimized
                          ? InkWell(
                              onTap: () => _fetchDailyAnalytics(day.date),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        DateFormat('dd')
                                            .format(DateTime.parse(day.date)),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.greenAccent
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('MMM')
                                            .format(DateTime.parse(day.date)),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.greenAccent
                                              : Colors.white60,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListTile(
                              onTap: () => _fetchDailyAnalytics(day.date),
                              title: Text(
                                DateFormat('EEEE, MMM dd, yyyy')
                                    .format(DateTime.parse(day.date)),
                                style: TextStyle(
                                  color: isSelected ? Colors.greenAccent : Colors.white,
                                  fontWeight:
                                      isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Social Time: ${_formatSeconds(day.socialTime)}',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Right side - Analytics details
        Expanded(
          child: _selectedDateData == null
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.greenAccent),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Summary for ${DateFormat('MMM dd, yyyy').format(DateTime.parse(_selectedDateData!.date))}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildStatisticsGrid(),
                      const SizedBox(height: 24),
                      _buildSentimentAnalysis(),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(
                icon: Icons.access_time,
                label: 'Total Social Time',
                value: _formatSeconds(_selectedDateData!.socialTime),
                color: Colors.greenAccent,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(
                icon: Icons.mic,
                label: 'Speaking Time',
                value: _formatSeconds(_selectedDateData!.totalSpeakingTime),
                color: Colors.blueAccent,
              )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(
                icon: Icons.headphones,
                label: 'Listening Time',
                value: _formatSeconds(_selectedDateData!.totalListeningTime),
                color: Colors.purpleAccent,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(
                icon: Icons.bar_chart,
                label: 'Speaking/Listening Ratio',
                value: _selectedDateData!.speakingToListeningRatio.toStringAsFixed(2),
                color: Colors.orangeAccent,
              )),
            ],
          ),
          const SizedBox(height: 16),
          // Ratio progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Speaking vs. Listening Balance',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_selectedDateData!.speakingToListeningRatio * 0.5).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  minHeight: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentAnalysis() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sentiment Analysis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSentimentItem(
                emoji: '😊',
                label: 'Positive',
                count: _selectedDateData!.positiveSentimentCount,
                color: Colors.greenAccent,
              ),
              _buildSentimentItem(
                emoji: '😐',
                label: 'Neutral',
                count: _selectedDateData!.neutralSentimentCount,
                color: Colors.blueAccent,
              ),
              _buildSentimentItem(
                emoji: '😟',
                label: 'Negative',
                count: _selectedDateData!.negativeSentimentCount,
                color: Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentItem({
    required String emoji,
    required String label,
    required int count,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// Analytics Summary model
class AnalyticsSummary {
  final String date;
  final double socialTime;

  AnalyticsSummary({
    required this.date,
    required this.socialTime,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      date: json['date'] ?? '',
      socialTime: (json['socialTime'] ?? json['social_time'] ?? 0).toDouble(),
    );
  }
}

// Daily Analytics model
class DailyAnalytics {
  final String date;
  final double socialTime;
  final double totalSpeakingTime;
  final double totalListeningTime;
  final double speakingToListeningRatio;
  final int positiveSentimentCount;
  final int neutralSentimentCount;
  final int negativeSentimentCount;

  DailyAnalytics({
    required this.date,
    required this.socialTime,
    required this.totalSpeakingTime,
    required this.totalListeningTime,
    required this.speakingToListeningRatio,
    required this.positiveSentimentCount,
    required this.neutralSentimentCount,
    required this.negativeSentimentCount,
  });

  factory DailyAnalytics.fromJson(Map<String, dynamic> json) {
    return DailyAnalytics(
      date: json['date'] ?? '',
      socialTime: (json['socialTime'] ?? json['social_time'] ?? 0).toDouble(),
      totalSpeakingTime:
          (json['totalSpeakingTime'] ?? json['total_speaking_time'] ?? 0).toDouble(),
      totalListeningTime:
          (json['totalListeningTime'] ?? json['total_listening_time'] ?? 0).toDouble(),
      speakingToListeningRatio:
          (json['speakingToListeningRatio'] ?? json['speaking_to_listening_ratio'] ?? 0).toDouble(),
      positiveSentimentCount:
          json['positive_sentiment_count'] ?? json['positiveSentimentCount'] ?? 0,
      neutralSentimentCount:
          json['neutral_sentiment_count'] ?? json['neutralSentimentCount'] ?? 0,
      negativeSentimentCount:
          json['negative_sentiment_count'] ?? json['negativeSentimentCount'] ?? 0,
    );
  }
}
