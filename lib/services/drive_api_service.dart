import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_pendant_app/services/local_storage_service.dart';

class DriveApiService {
  final String _baseUrl = 'https://shreeyanshsingh-raghuvanshi-kairob.hf.space/api/drive';

  Future<List<dynamic>> listFiles() async {
    final storage = LocalStorageService.instance;
    final token = storage.getAuthToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/files'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load files');
    }
  }
}
