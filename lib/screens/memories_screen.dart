import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:smart_pendant_app/services/local_storage_service.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  bool loading = true;
  String? error;
  List<dynamic> memories = [];
  List<dynamic> filtered = [];

  String searchTerm = '';
  String dateFilter = '';
  String sentimentFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchMemories();
  }

  Future<void> _fetchMemories() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final storage = LocalStorageService.instance;
      final userId = storage.getUserId();
      if (userId == null) {
        setState(() {
          error = 'User not found. Please login.';
          loading = false;
        });
        return;
      }

      final url = Uri.parse(
          'https://keshavsuthar-kairo-api.hf.space/memories/user/$userId');
      final resp = await http.get(url).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        setState(() {
          error = 'Failed to load memories (${resp.statusCode}).';
          loading = false;
        });
        return;
      }

      final body = json.decode(resp.body);
      final List<dynamic> data = body is List ? body : [body];

      data.sort((a, b) {
        final da = DateTime.tryParse(
                a['created_at']?['\u0024date']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final db = DateTime.tryParse(
                b['created_at']?['\u0024date']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });

      setState(() {
        memories = data;
        _applyFilters();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Could not load memories.';
        loading = false;
      });
    }
  }

  void _applyFilters() {
    final s = searchTerm.toLowerCase();
    filtered = memories.where((m) {
      if (m == null) return false;
      final title = (m['title'] ?? '').toString().toLowerCase();
      final summary = (m['summary'] ?? '').toString().toLowerCase();
      final mom = (m['mom'] ?? '').toString().toLowerCase();

      final searchMatch = s.isEmpty ||
          title.contains(s) ||
          summary.contains(s) ||
          mom.contains(s);

      final dateMatch = dateFilter.isEmpty ||
          (m['created_at']?['\u0024date']?.toString() ?? '')
              .startsWith(dateFilter);

      final sentimentLabel =
          (m['sentiment']?['label'] ?? '').toString().toLowerCase();
      final sentimentMatch = sentimentFilter == 'all' ||
          sentimentLabel.contains(sentimentFilter.toLowerCase());

      return searchMatch && dateMatch && sentimentMatch;
    }).toList();
  }

  void _openMemoryDetail(dynamic memory) {
    bool showTranscript = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: const Color(0xFF0D0D12),
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(memory['title'] ?? 'Memory',
                              style: GoogleFonts.oxanium(
                                  fontSize: 20, fontWeight: FontWeight.bold))),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text((memory['created_at']?['\u0024date'] ?? '').toString(),
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((memory['summary'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            const Text('Summary',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(memory['summary'] ?? '',
                                style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 12),
                          ],
                          if ((memory['mom'] ?? '').toString().isNotEmpty) ...[
                            const Text('Minutes of Meeting',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(memory['mom'] ?? '',
                                style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 12),
                          ],
                          if (memory['sentiment'] != null) ...[
                            const Text('Sentiment',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF0B1220),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                  '${memory['sentiment']?['label'] ?? ''}: ${memory['sentiment']?['justification'] ?? ''}',
                                  style:
                                      const TextStyle(color: Colors.white70)),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (memory['action_items'] != null &&
                              (memory['action_items'] as List).isNotEmpty) ...[
                            const Text('Action Items',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            ...((memory['action_items'] as List).map((a) =>
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Text(
                                        '- ${a.toString()}',
                                        style: const TextStyle(
                                            color: Colors.white70))))),
                            const SizedBox(height: 12),
                          ],
                          if ((memory['full_transcription'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Full Transcript',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                GestureDetector(
                                  onTap: () => setState(
                                      () => showTranscript = !showTranscript),
                                  child: Row(
                                    children: [
                                      Icon(
                                          showTranscript
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: const Color(0xFF4285F4),
                                          size: 20),
                                      const SizedBox(width: 4),
                                      Text(showTranscript ? 'Hide' : 'Show',
                                          style: const TextStyle(
                                              color: Color(0xFF4285F4),
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (showTranscript) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF0B1220),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(memory['full_transcription'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.white70, height: 1.6)),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedList() {
    final Map<String, List<dynamic>> groups = {};
    for (var m in filtered) {
      final createdRaw = m['created_at']?['\u0024date']?.toString() ?? '';
      DateTime dt;
      try {
        dt = DateTime.parse(createdRaw);
      } catch (_) {
        dt = DateTime.fromMillisecondsSinceEpoch(0);
      }
      final header = _formatDateHeader(dt);
      groups.putIfAbsent(header, () => []).add(m);
    }

    final sortedKeys = groups.keys.toList();

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: sortedKeys.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final key = sortedKeys[idx];
        final items = groups[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              child: Text(key,
                  style: GoogleFonts.oxanium(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Column(
                children: items.map((m) => _buildMemoryListTile(m)).toList()),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime dt) {
    if (dt.year == 0) return 'Unknown Date';
    final day = dt.day;
    final suffix = (day >= 11 && day <= 13)
        ? 'th'
        : (day % 10 == 1)
            ? 'st'
            : (day % 10 == 2)
                ? 'nd'
                : (day % 10 == 3)
                    ? 'rd'
                    : 'th';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '$day$suffix ${months[dt.month - 1]}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  Widget _buildMemoryListTile(dynamic memory) {
    final createdRaw = memory['created_at']?['\u0024date']?.toString() ?? '';
    DateTime dt;
    try {
      dt = DateTime.parse(createdRaw);
    } catch (_) {
      dt = DateTime.fromMillisecondsSinceEpoch(0);
    }
    final timeStr = _formatTime(dt);
    final duration = (memory['duration'] ?? memory['length'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
      child: InkWell(
        onTap: () => _openMemoryDetail(memory),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF101214),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(memory['title'] ?? 'Untitled',
                        style: GoogleFonts.oxanium(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Color(0xFF00D38A)),
                ],
              ),
              const SizedBox(height: 8),
              Text(memory['summary'] ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(timeStr,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                  if (duration.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Colors.white24)),
                    const SizedBox(width: 8),
                    Text(duration,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Memories', style: GoogleFonts.oxanium()),
          backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search memories...'),
                onChanged: (v) => setState(() {
                  searchTerm = v;
                  _applyFilters();
                }),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 140,
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today),
                    hintText: 'YYYY-MM-DD'),
                onChanged: (v) => setState(() {
                  dateFilter = v;
                  _applyFilters();
                }),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: sentimentFilter,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'positive', child: Text('Positive')),
                DropdownMenuItem(value: 'neutral', child: Text('Neutral')),
                DropdownMenuItem(value: 'negative', child: Text('Negative')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  sentimentFilter = v;
                  _applyFilters();
                });
              },
            ),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : (error != null
                    ? Center(
                        child: Text(error!,
                            style: const TextStyle(color: Colors.redAccent)))
                    : (filtered.isEmpty
                        ? Center(
                            child: Text('No memories',
                                style: GoogleFonts.oxanium()))
                        : _buildGroupedList())),
          ),
        ]),
      ),
    );
  }
}
