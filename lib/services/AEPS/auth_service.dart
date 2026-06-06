import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Save merchant data locally
  Future<void> saveMerchantData({
    required String merchantId,
    required String merchantRefId,
    required String mobileNo,
    String? aadhaarNo,
  }) async {
    await _storage.write(key: 'merchant_id', value: merchantId);
    await _storage.write(key: 'merchant_ref_id', value: merchantRefId);
    await _storage.write(key: 'mobile_no', value: mobileNo);
    if (aadhaarNo != null) {
      await _storage.write(key: 'aadhaar_no', value: aadhaarNo);
    }
  }
  
  // Get merchant data
  Future<Map<String, String?>> getMerchantData() async {
    return {
      'merchantId': await _storage.read(key: 'merchant_id'),
      'merchantRefId': await _storage.read(key: 'merchant_ref_id'),
      'mobileNo': await _storage.read(key: 'mobile_no'),
      'aadhaarNo': await _storage.read(key: 'aadhaar_no'),
    };
  }
  
  // Clear merchant data (logout)
  Future<void> clearMerchantData() async {
    await _storage.delete(key: 'merchant_id');
    await _storage.delete(key: 'merchant_ref_id');
    await _storage.delete(key: 'mobile_no');
    await _storage.delete(key: 'aadhaar_no');
  }
  
  // Check if merchant is registered
  Future<bool> isMerchantRegistered() async {
    final merchantId = await _storage.read(key: 'merchant_id');
    return merchantId != null && merchantId.isNotEmpty;
  }
}