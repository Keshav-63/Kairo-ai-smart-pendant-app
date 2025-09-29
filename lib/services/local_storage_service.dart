import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class LocalStorageService {
  static LocalStorageService? _instance;
  static SharedPreferences? _preferences;

  static const String _userIdKey = 'userId';
  static const String _authTokenKey = 'authToken';
  static const String _onboardingCompleteKey = 'onboardingComplete';

  // Private constructor
  LocalStorageService._();

  // Singleton accessor
  static LocalStorageService get instance {
    if (_instance == null) {
      throw Exception("LocalStorageService not initialized. Call LocalStorageService.init() in main.");
    }
    return _instance!;
  }

  // One-time initialization
  static Future<void> init() async {
    if (_instance == null) {
      debugPrint("Initializing LocalStorageService...");
      _instance = LocalStorageService._();
      _preferences = await SharedPreferences.getInstance();
      debugPrint("LocalStorageService Initialized.");
    }
  }

  // Helper method to get preferences instance
  SharedPreferences _getPrefs() {
    if (_preferences == null) {
      throw Exception("SharedPreferences not initialized.");
    }
    return _preferences!;
  }

  Future<void> saveUserId(String userId) async {
    await _getPrefs().setString(_userIdKey, userId);
  }

  String? getUserId() {
    return _getPrefs().getString(_userIdKey);
  }

  Future<void> saveAuthToken(String token) async {
    await _getPrefs().setString(_authTokenKey, token);
  }

  String? getAuthToken() {
    return _getPrefs().getString(_authTokenKey);
  }

  Future<void> clearAllData() async {
    await _getPrefs().clear();
    debugPrint("All data cleared from local storage.");
  }

  Future<void> setHasCompletedOnboarding(bool completed) async {
    await _getPrefs().setBool(_onboardingCompleteKey, completed);
  }

  bool hasCompletedOnboarding() {
    return _getPrefs().getBool(_onboardingCompleteKey) ?? false;
  }
}