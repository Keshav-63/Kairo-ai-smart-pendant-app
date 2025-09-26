import 'dart:async';

class PendantApiService {
  Future<bool> sendWifiCredentials({
    required String ssid,
    required String password,
    required String userId,
  }) async {
    // --- DEMO MODE ---
    // We will pretend to connect and always return true after a short delay.
    print('--- DEMO MODE: Pretending to send credentials ---');
    await Future.delayed(const Duration(seconds: 2)); // Simulate a 2-second network delay
    print('--- DEMO MODE: Connection successful! ---');
    return true; // This makes it ALWAYS succeed!
  }
}