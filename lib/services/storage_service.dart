// services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static SharedPreferences? _prefs;
  static const String _senderMobileKey = 'sender_mobile';
  static const String _senderDataKey = 'sender_data';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _loggedInUserId = 'logged_in_user_id';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }


  // Onboarding Status
  static Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs?.setBool(_onboardingCompletedKey, completed);
  }

  static bool hasCompletedOnboarding() {
    return _prefs?.getBool(_onboardingCompletedKey) ?? false;
  }

  // Sender Data
  static Future<void> saveSenderData(Map<String, dynamic> data) async {
    final jsonString = data.toString();
    await _prefs?.setString(_senderDataKey, jsonString);
  }

  static Map<String, dynamic>? getSenderData() {
    final data = _prefs?.getString(_senderDataKey);
    if (data != null) {
      // Parse JSON properly in production
      return {};
    }
    return null;
  }

  static Future<void> setToken(String token) async {
    await _prefs?.setString(_tokenKey, token);
  }

  static String? getToken() {
    return _prefs?.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    await _prefs?.remove(_tokenKey);
  }

  static Future<void> saveSenderMobile(String mobile) async {
    await _prefs?.setString(_senderMobileKey, mobile);
  }


  static Future<String?> getSenderMobile() async {
    return _prefs?.getString(_senderMobileKey);
  }

  static Future<void> setUserData(Map<String, dynamic> userData) async {
    final jsonString = userData.toString();
    await _prefs?.setString('user_data', jsonString);
  }

  static Future<void> setLoggedInUserId(String userId) async {
    await _prefs?.setString(_loggedInUserId, userId);
  }

  static String? getLoggedInUserId() {
    return _prefs?.getString(_loggedInUserId);
  }

  static Future<void> clearAll() async {
    await _prefs?.clear();
  }


  static Map<String, dynamic>? getUserData() {
    final data = _prefs?.getString('user_data');
    if (data != null) {
      // Parse JSON here if needed
      return {};
    }
    return null;
  }
}