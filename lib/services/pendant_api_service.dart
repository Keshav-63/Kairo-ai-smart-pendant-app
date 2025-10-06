import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:wifi_scan/wifi_scan.dart';
import 'package:flutter/foundation.dart';

class PendantApiService {
  // The static IP address of the pendant when it's in hotspot mode.
  static const String _pendantBaseUrl = 'http://192.168.4.1';

  // Scans for and returns a list of nearby Wi-Fi networks.
  Future<List<WiFiAccessPoint>> getNearbyWifiNetworks() async {
    final canScan = await WiFiScan.instance.canStartScan();
    if (canScan != CanStartScan.yes) {
      return [];
    }
    await WiFiScan.instance.startScan();
    return await WiFiScan.instance.getScannedResults();
  }

  // Sends the selected home Wi-Fi credentials and userId to the pendant.
  Future<bool> provisionDevice({
    required String ssid,
    required String password,
    required String userId,
  }) async {
    final url = Uri.parse('$_pendantBaseUrl/save');
    debugPrint("Provisioning device at $url with SSID: $ssid and UserID: $userId");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'ssid': ssid,
          'pass': password,
          'userId': userId,
        },
      ).timeout(const Duration(seconds: 45));

      debugPrint("Pendant response status: ${response.statusCode}");
      debugPrint("Pendant response body: ${response.body}");

      // The firmware should return a 200 OK on success.
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error provisioning device: $e");
      // This could be a timeout or a connection error.
      return false;
    }
  }
}