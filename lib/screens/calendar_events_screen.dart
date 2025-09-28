import 'package:flutter/material.dart';
import 'package:smart_pendant_app/services/calendar_api_service.dart';

class CalendarEventsScreen extends StatefulWidget {
  const CalendarEventsScreen({super.key});

  @override
  State<CalendarEventsScreen> createState() => _CalendarEventsScreenState();
}

class _CalendarEventsScreenState extends State<CalendarEventsScreen> {
  late Future<List<dynamic>> _events;

  @override
  void initState() {
    super.initState();
    _events = CalendarApiService().listEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Calendar Events'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _events,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(snapshot.data![index]['summary']),
                  subtitle: Text(snapshot.data![index]['start']['dateTime']),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text("${snapshot.error}"),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}