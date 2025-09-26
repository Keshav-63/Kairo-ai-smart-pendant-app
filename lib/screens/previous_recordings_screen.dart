import 'package:flutter/material.dart';

// Simple class for mock data
class RecordingSession {
  final String topic;
  final String date;
  final String time;
  RecordingSession({required this.topic, required this.date, required this.time});
}

class PreviousRecordingsScreen extends StatelessWidget {
  PreviousRecordingsScreen({super.key});

  // Mock data for the list
  final List<RecordingSession> _recordings = [
    RecordingSession(topic: 'Project brainstorming meeting', date: '25 Sep 2025', time: '4:30 PM'),
    RecordingSession(topic: 'Quarterly review with manager', date: '24 Sep 2025', time: '11:00 AM'),
    RecordingSession(topic: 'Client call notes', date: '22 Sep 2025', time: '2:15 PM'),
    RecordingSession(topic: 'Lecture on Flutter State Management', date: '20 Sep 2025', time: '9:00 AM'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // THEME UPDATE
      appBar: AppBar(
        title: const Text('Previous Recordings'),
      ),
      body: ListView.builder(
        itemCount: _recordings.length,
        itemBuilder: (context, index) {
          final recording = _recordings[index];
          return Card(
            color: Colors.grey.shade900,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.play_circle_outline, color: Colors.indigoAccent),
              title: Text(recording.topic),
              subtitle: Text('${recording.date} at ${recording.time}'),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}