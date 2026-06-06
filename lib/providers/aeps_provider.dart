import 'dart:developer' as DebugLogger;

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart'; // added for IP retrieval
import '../services/AEPS/api_service.dart';
import '../services/AEPS/auth_service.dart';
import '../models/aeps_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AepsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  
  // State variables
  List<Bank> _banks = [];
  List<AepsStateModel> _states = [];
  List<District> _districts = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Merchant data
  String? _merchantId;
  String? _merchantRefId;
  String? _mobileNo;
  String? _aadhaarNo;

  // ==================== NEW AUTH FIELDS ====================
  String? _authToken;      // Bearer token
  String? _userId;         // User Id from onboarding
  String? _ipAddress;      // Local IP address
  String? _pipe = '1';     // Default pipe as per API documentation

static const String _keyAuthToken = 'auth_token';
static const String _keyUserId = 'auth_user_id';
String? _realMerchantId;
String? get realMerchantId => _realMerchantId;

  // Getters
  List<Bank> get banks => _banks;
  List<AepsStateModel> get states => _states;
  List<District> get districts => _districts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get merchantId => _merchantId;
  String? get merchantRefId => _merchantRefId;
  String? get mobileNo => _mobileNo;
  String? get aadhaarNo => _aadhaarNo;

  // Daily 2FA
  bool _is2FAVerifiedToday = false;
  String? _last2FADate;
  static const String _keyLast2FADate = 'last_2fa_date';

  bool get is2FAVerifiedToday => _is2FAVerifiedToday;
  bool get isMerchantActive => _merchantId != null && _merchantId!.isNotEmpty;

  // ==================== NEW GETTERS ====================
  // String? get authToken => _authToken;
  // String? get userId => _userId;
  String? get ipAddress => _ipAddress;
  String? get pipe => _pipe;

  /// Initialize provider and load persisted data
  Future<void> init() async {
    await _loadPersistedData();
  }

  /// Call after login to set authentication and merchant details
  void setAuthDetails({
    required String token,
    required String userId,
    required String merchantId,
    String? mobileNo,
    String? pipe,
  }) {

  DebugLogger.log('🔐 setAuthDetails called');
  DebugLogger.log('   token: ${token.isNotEmpty ? token.substring(0, 20) + "..." : "EMPTY"}');
  DebugLogger.log('   userId: $userId');
  DebugLogger.log('   merchantId: $merchantId');

    _authToken = token;
    _userId = userId;
    _merchantId = merchantId;
    _mobileNo = mobileNo;
    _pipe = pipe ?? '1';
    _getLocalIp(); // fetch IP asynchronously
    _persistAuthToken(token, userId); // ← ADD THIS
    notifyListeners();
  }

Future<void> _persistAuthToken(String token, String userId) async {
  
  try{
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
  await prefs.setString('auth_user_id', userId);

    DebugLogger.log('💾 Auth details persisted to SharedPreferences');
  } catch (e) {
    DebugLogger.log('❌ Failed to persist auth details: $e');
  }
}

  Future<void> _getLocalIp() async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      _ipAddress = (ip != null && ip.isNotEmpty) ? ip : '127.0.0.1';
    } catch (e) {
      _ipAddress = '127.0.0.1';
    }
    notifyListeners();
  }

  /// Load persisted data (call in init())
  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _last2FADate = prefs.getString(_keyLast2FADate);
      DebugLogger.log('📱 Loaded last 2FA date from storage: $_last2FADate');
      

// ← ADD THESE TWO LINES
    _authToken   = prefs.getString(_keyAuthToken);
    _userId      = prefs.getString(_keyUserId);

    DebugLogger.log('📦 _loadPersistedData:');
    DebugLogger.log('   _last2FADate : $_last2FADate');
    DebugLogger.log('   _authToken   : ${_authToken != null ? _authToken!.substring(0, 20) + "..." : "NULL ❌"}');
    DebugLogger.log('   _userId      : ${_userId ?? "NULL ❌"}');

      final today = DateTime.now().toIso8601String().split('T')[0];
      _is2FAVerifiedToday = _last2FADate == today;
      DebugLogger.log('📱 Is verified today: $_is2FAVerifiedToday');
    } catch (e) {
      DebugLogger.log('❌ Error loading persisted data: $e');
    }
  }

  /// Save last 2FA date to storage
  Future<void> _saveLast2FADate(String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLast2FADate, date);
      DebugLogger.log('💾 Saved last 2FA date: $date');
    } catch (e) {
      DebugLogger.log('❌ Error saving last 2FA date: $e');
    }
  }

  /// Returns true if the merchant needs to verify again today
  bool needs2FA() {
    if (_merchantId == null || _merchantId!.isEmpty) return false;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final needs = _last2FADate != today;
    DebugLogger.log('🔍 Checking needs2FA: lastDate=$_last2FADate, today=$today, needs=$needs');
    return needs;
  }


  Future<void> fetchMerchantByPhone(String phone) async {
  final response = await _apiService.getMerchantByPhone(phone);
  if (response['success'] == true) {
    _realMerchantId = response['data']['merchantId'];
    notifyListeners();
  }
}

  /// Perform the daily 2FA (biometric) call
  Future<bool> performDaily2FA(
    String pidData, {
    String deviceType = 'mantra',
    String? aadhaarNumber,
    String? merchantRefId,
  }) async {
    if (_merchantId == null) return false;

    final aadhaar = aadhaarNumber ?? _aadhaarNo;
    if (aadhaar == null || aadhaar.isEmpty) {
      _errorMessage = 'Aadhaar number is required';
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.twoFactorAuth(
        _merchantId!,
        aadhaar,
        pidData,
        deviceType,
        merchantRefId ?? '2FA_${DateTime.now().millisecondsSinceEpoch}',
      );

      final today = DateTime.now().toIso8601String().split('T')[0];
      _last2FADate = today;
      _is2FAVerifiedToday = true;
      _errorMessage = null;
      await _saveLast2FADate(today);
      DebugLogger.log('✅ 2FA verification successful for date: $today');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load merchant data on start
  Future<void> loadMerchantData() async {
    final data = await _authService.getMerchantData();
    _merchantId = data['merchantId'];
    _merchantRefId = data['merchantRefId'];
    _mobileNo = data['mobileNo'];
    _aadhaarNo = data['aadhaarNo'];
    notifyListeners();
  }
  
  // Clear merchant data (for logout)
Future<void> clearMerchantData() async {
  await _authService.clearMerchantData();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keyAuthToken);
  await prefs.remove(_keyUserId);
  DebugLogger.log('🗑️ Auth details cleared from SharedPreferences');

  _merchantId         = null;
  _merchantRefId      = null;
  _mobileNo           = null;
  _aadhaarNo          = null;
  _is2FAVerifiedToday = false;
  _last2FADate        = null;
  _authToken          = null;
  _userId             = null;
  _ipAddress          = null;
  _pipe               = '1';
  notifyListeners();
}
  
  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // 1. Fetch Banks
  Future<void> fetchBanks() async {
    _isLoading = true;
    notifyListeners();
    try {
      _banks = await _apiService.getBankList();
      DebugLogger.log('✅ Banks loaded: ${_banks.length}');
    } catch (e) {
      DebugLogger.log('❌ fetchBanks error: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 2. Fetch States
  Future<List<AepsStateModel>> getStateList() async {
    _isLoading = true;
    notifyListeners();
    try {
      _states = await _apiService.getStateList();
      debugPrint('✅ States loaded: ${_states.length}');
      for (var s in _states) {
        debugPrint('   → code: ${s.code}, name: ${s.name}');
      }
      return _states;
    } catch (e) {       
      debugPrint('❌ Failed to load states: $e');
      _errorMessage = e.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setMerchantData(Map<String, dynamic> merchant) {
    _merchantId = merchant['merchantId']?.toString();
    _merchantRefId = merchant['merchantRefId']?.toString();
    _mobileNo = merchant['phone']?.toString();
    _aadhaarNo = merchant['aadhaarNo']?.toString();
    _last2FADate = null;
    _is2FAVerifiedToday = false;
    _authService.saveMerchantData(
      merchantId: _merchantId ?? '',
      merchantRefId: _merchantRefId ?? '',
      mobileNo: _mobileNo ?? '',
      aadhaarNo: _aadhaarNo,
    );
    notifyListeners();
  }

  // Get transaction status
  Future<Map<String, dynamic>> getTransactionStatus(String merchantId, String merchantRefId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.getTransactionStatus(merchantId, merchantRefId);
      return response;
    } catch (e) {
      _errorMessage = e.toString();
      return {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
bool _isLoadingDistricts = false;
bool get isLoadingDistricts => _isLoadingDistricts;
  // 3. Fetch Districts
  Future<void> fetchDistricts(String stateCode) async {
    _isLoadingDistricts = true;
    notifyListeners();
    try {
      _districts = await _apiService.getDistrictList(stateCode);
    } catch (e) {
      _errorMessage = e.toString();
      _districts = [];
    } finally {
      _isLoadingDistricts = false;
      notifyListeners();
    }
  }
  
  // 4. Register Merchant
Future<bool> registerMerchant(MerchantRegistrationRequest request) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();
  try {
    final response = await _apiService.registerMerchant(request);
    if (response['success'] == true) {
      // ✅ Correct: extract from nested 'data'
      final data = response['data'] as Map<String, dynamic>;
      _merchantId = data['merchantId'];
      _merchantRefId = data['merchantRefId'] ?? response['merchantRefId'] ?? request.mobileNo;
      _mobileNo = request.mobileNo;
      return true;
    } else {
      _errorMessage = response['message'] ?? 'Registration failed';
      return false;
    }
  } catch (e) {
    _errorMessage = e.toString();
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
  
  // 5. Send OTP
 Future<bool> sendOtp(String merchantId, String mobileNo) async {
  _isLoading = true;
  try {
    final response = await _apiService.sendOtp(merchantId, mobileNo);
    print('🔍 Send OTP response: $response');
    if (response['success'] == true) {
      return true;
    } else {
      _errorMessage = response['message'] ?? 'OTP send failed';
      return false;
    }
  } catch (e) {
    _errorMessage = e.toString();
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
  
  // 6. Verify OTP
  Future<bool> verifyOtp(String merchantId, String otp, String merchantRefId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _apiService.verifyOtp(merchantId, otp, merchantRefId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // ==================== UPDATED AEPS TRANSACTION METHODS ====================
  // 7. AEPS Transaction using the full request (matches API documentation)
Future<TransactionResponse?> executeTransaction(AepsTransactionRequest request) async {
  DebugLogger.log('\n========== executeTransaction ==========');
  DebugLogger.log('   _authToken : ${_authToken != null ? _authToken!.substring(0, 20) + "..." : "NULL ❌"}');
  DebugLogger.log('   _userId    : ${_userId ?? "NULL ❌"}');
  DebugLogger.log('   _merchantId: ${_merchantId ?? "NULL ❌"}');
  DebugLogger.log('   _ipAddress : ${_ipAddress ?? "NULL ❌"}');
  DebugLogger.log('========================================\n');

  if (_authToken == null || _authToken!.isEmpty) {
    _errorMessage = 'Auth token missing. Please logout and login again.';
    DebugLogger.log('❌ BLOCKED: _authToken is null/empty');
    notifyListeners();
    return null;
  }
  if (_userId == null || _userId!.isEmpty) {
    _errorMessage = 'User ID missing. Please logout and login again.';
    DebugLogger.log('❌ BLOCKED: _userId is null/empty');
    notifyListeners();
    return null;
  }

  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    DebugLogger.log('📤 Calling aepsTransaction API...');
    final response = await _apiService.aepsTransaction(
      request,
      token: _authToken!,
      userId: _userId!,
    );
    DebugLogger.log('✅ Transaction response received');
    return response;
  } catch (e) {
    DebugLogger.log('❌ Transaction API error: $e');
    _errorMessage = e.toString();
    return null;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  /// Helper method to build AepsTransactionRequest from screen inputs
Future<TransactionResponse?> performAepsTransaction({
   required String merchantId,

  required String transactionType,
  required String aadhaarNumber,
  required String bankIIN,
  required String amount,
  required String pidData,
  required String deviceType,
  required String merchantRefId,
  required String mobileNo,
}) async {
  DebugLogger.log('\n========== performAepsTransaction ==========');
  DebugLogger.log('   transactionType : $transactionType');
  DebugLogger.log('   aadhaarNumber   : ${aadhaarNumber.replaceRange(4, 8, "XXXX")}');
  DebugLogger.log('   bankIIN         : $bankIIN');
  DebugLogger.log('   amount          : $amount');
  DebugLogger.log('   deviceType      : $deviceType');
  DebugLogger.log('   merchantRefId   : $merchantRefId');
  DebugLogger.log('   mobileNo        : $mobileNo');
  DebugLogger.log('   _merchantId     : ${_merchantId ?? "NULL ❌"}');
  DebugLogger.log('   _authToken      : ${_authToken != null ? "SET ✓" : "NULL ❌"}');
  DebugLogger.log('   _userId         : ${_userId ?? "NULL ❌"}');
  DebugLogger.log('   _ipAddress      : ${_ipAddress ?? "NULL - will fetch"}');
  DebugLogger.log('============================================\n');

  if (_merchantId == null || _merchantId!.isEmpty) {
    throw Exception('Merchant ID not set');
  }

  if (_authToken == null || _authToken!.isEmpty) {
    // Try reloading from SharedPreferences before giving up
    DebugLogger.log('⚠️ _authToken null in performAepsTransaction — attempting reload from prefs...');
    await _loadPersistedData();
    DebugLogger.log('   After reload — _authToken: ${_authToken != null ? "SET ✓" : "STILL NULL ❌"}');
    DebugLogger.log('   After reload — _userId   : ${_userId ?? "STILL NULL ❌"}');
  }

  if (_ipAddress == null) {
    await _getLocalIp();
  }
  _pipe ??= '1';

  final request = AepsTransactionRequest(
    transactionType: transactionType,
    amount: amount,
    aadhaarNumber: aadhaarNumber,
    bankIIN: bankIIN,
    merchantId: _merchantId!,
    mobileNo: mobileNo,
    ipAddress: _ipAddress!,
    pidData: pidData,
    pipe: _pipe!,
    merchantRefId: merchantRefId,
    deviceType: deviceType,
  );

  return await executeTransaction(request);
}

  void setMobileNo(String mobile) {
    _mobileNo = mobile;
    notifyListeners();
  }
}