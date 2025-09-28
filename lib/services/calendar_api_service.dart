import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_pendant_app/services/local_storage_service.dart';

class CalendarApiService {
  final String _baseUrl = 'http://localhost:3001/api/calendar';

  Future<List<dynamic>> listEvents() async {
    final storage = LocalStorageService();
    final token = await storage.getAuthToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/events'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load events');
    }
  }
}