import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  // Keys
  static const String _tokenKey = 'auth_token';
  static const String _senderMobileKey = 'sender_mobile';
  static const String _senderDataKey = 'sender_data';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _loggedInUserId = 'logged_in_user_id';
  static const String _userDataKey = 'user_data';

  // New keys for Vimopay DMT
  static const String _agentCodeKey = 'vimo_agent_code';
  static const String _beneAccIdPrefix = 'bene_acc_id_';

  // Add these keys
static const String _senderNameKey = 'sender_name';
static const String _senderAccountKey = 'sender_account';
static const String _senderIfscKey = 'sender_ifsc';
static const String _monthlyLimitKey = 'monthly_limit';
static const String _monthlyUsedKey = 'monthly_used';

// Getters and setters
static Future<void> saveSenderName(String name) async {
  await _prefs?.setString(_senderNameKey, name);
}
static Future<String?> getSenderName() async {
  return _prefs?.getString(_senderNameKey);
}

static Future<void> saveSenderAccountNumber(String acc) async {
  await _prefs?.setString(_senderAccountKey, acc);
}
static Future<String?> getSenderAccountNumber() async {
  return _prefs?.getString(_senderAccountKey);
}

static Future<void> saveSenderIfsc(String ifsc) async {
  await _prefs?.setString(_senderIfscKey, ifsc);
}
static Future<String?> getSenderIfsc() async {
  return _prefs?.getString(_senderIfscKey);
}

static Future<void> saveMonthlyLimit(double limit) async {
  await _prefs?.setDouble(_monthlyLimitKey, limit);
}
static Future<double?> getMonthlyLimit() async {
  return _prefs?.getDouble(_monthlyLimitKey);
}

static Future<void> saveMonthlyUsed(double used) async {
  await _prefs?.setDouble(_monthlyUsedKey, used);
}
static Future<double?> getMonthlyUsed() async {
  return _prefs?.getDouble(_monthlyUsedKey);
}

  // Initialization
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ------------------- Onboarding -------------------
  static Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs?.setBool(_onboardingCompletedKey, completed);
  }

  static bool hasCompletedOnboarding() {
    return _prefs?.getBool(_onboardingCompletedKey) ?? false;
  }

  // ------------------- Sender Data (JSON) -------------------
  static Future<void> saveSenderData(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    await _prefs?.setString(_senderDataKey, jsonString);
  }

  static Map<String, dynamic>? getSenderData() {
    final data = _prefs?.getString(_senderDataKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  // ------------------- Auth Token -------------------
  static Future<void> setToken(String token) async {
    await _prefs?.setString(_tokenKey, token);
  }

  static String? getToken() {
    return _prefs?.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    await _prefs?.remove(_tokenKey);
  }

  // ------------------- Sender Mobile -------------------
  static Future<void> saveSenderMobile(String mobile) async {
    await _prefs?.setString(_senderMobileKey, mobile);
  }

  static Future<String?> getSenderMobile() async {
    return _prefs?.getString(_senderMobileKey);
  }

  // ------------------- User Data -------------------
  static Future<void> setUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _prefs?.setString(_userDataKey, jsonString);
  }

  static Map<String, dynamic>? getUserData() {
    final data = _prefs?.getString(_userDataKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> setLoggedInUserId(String userId) async {
    await _prefs?.setString(_loggedInUserId, userId);
  }

  static String? getLoggedInUserId() {
    return _prefs?.getString(_loggedInUserId);
  }

  // ------------------- Vimopay DMT: Agent Code -------------------
  static Future<void> saveAgentCode(String code) async {
    await _prefs?.setString(_agentCodeKey, code);
  }

  static Future<String?> getAgentCode() async {
    return _prefs?.getString(_agentCodeKey);
  }

  // ------------------- Vimopay DMT: Beneficiary AccId -------------------
  static Future<void> saveBeneAccId(String benecode, String beneAccId) async {
    await _prefs?.setString('$_beneAccIdPrefix$benecode', beneAccId);
  }

  static Future<String?> getBeneAccId(String benecode) async {
    return _prefs?.getString('$_beneAccIdPrefix$benecode');
  }

  // ------------------- Clear All -------------------
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}