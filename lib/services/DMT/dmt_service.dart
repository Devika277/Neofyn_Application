import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:my_app/services/storage_service.dart';

class DMTService {
  late Dio _dio;
  final String baseUrl;

  DMTService(this.baseUrl) {
    // Ensure baseUrl ends with a slash (or add it)
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    _dio = Dio(BaseOptions(baseUrl: cleanBaseUrl));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // Helper for location (implement as needed)
  Future<Map<String, String>> _getLocation() async {
    // TODO: implement actual GPS and IP fetching
    return {
      'ip': '127.0.0.1',
      'lat': '0.0',
      'long': '0.0',
    };
  }

  // ---------- MASTER DATA (no encryption) ----------
  Future<dynamic> fetchStates() async {
    // ✅ Correct endpoint: /api/dmt/states
    final response = await _dio.get('/api/dmt/states');
    return response.data;
  }

  // ✅ Changed to POST with body { stateCode }
// Flutter
Future<dynamic> fetchCities(String stateCode) async {
  final response = await _dio.get(
    '/api/dmt/cities',
    queryParameters: {'stateCode': stateCode.trim()},
  );
  return response.data;
}

  Future<dynamic> fetchBanks() async {
    final response = await _dio.get('/api/dmt/banks');
    return response.data;
  }

  // ---------- DMT OPERATIONS ----------
Future<dynamic> syncBeneficiaryWithLocalDb(Map<String, dynamic> data) async {
  final response = await _dio.post('/api/dmt/beneficiary/sync-local', data: {
    'remitterId': data['senderMobile'],
    'accountHolderName': data['beneName'],
    'accountNumber': data['accountNo'],
    'ifscCode': data['ifsc'],
    'bankName': data['bankName'],
    'beneCode': data['beneCode'],
    'accountType': data['accountType'],
    'cityCode': data['cityCode'],
    'pennyDropName': data['pennyDropName'],
    'beneCity': data['beneCity'],
    'beneState': data['beneState'],
  });
  return response.data;
}



Future<dynamic> agentLogin(String mobile, String pan) async {
  final response = await _dio.post('/api/agent/login', data: {
    'agentMobile': mobile,
    'agentPan': pan,
  });
  return response.data;
}

  Future<dynamic> registerAgent(Map<String, dynamic> data) async {
    final loc = await _getLocation();
    final payload = {
      ...data,
      'ip': loc['ip'],
      'lat': loc['lat'],
      'long': loc['long'],
    };
    final response = await _dio.post('/api/dmt/agent/register', data: payload);
    return response.data;
  }



Future<dynamic> performPennyDrop(String accountNo, String ifsc) async {
  final loc = await _getLocation();
  final payload = {
    'beneficiaryAccountNumber': accountNo,   // ✅ correct key
    'beneficiaryIFSC': ifsc,                 // ✅ correct key
    'ip': loc['ip'],
    'lat': loc['lat'],
    'long': loc['long'],
  };
  final response = await _dio.post('/api/dmt/penny-drop', data: payload);
  return response.data;
}





  Future<dynamic> resendTransactionOtp(String beneAccId) async {
    final response = await _dio.post('/api/dmt/otp/resend', data: {'beneAccId': beneAccId});
    return response.data;
  }

  Future<dynamic> registerSender(Map<String, dynamic> data) async {
    final loc = await _getLocation();
    final agentCode = await StorageService.getAgentCode();
    final payload = {
      ...data,
      'agentCode': agentCode,
      'ip': loc['ip'],
      'lat': loc['lat'],
      'long': loc['long'],
      'pidData': '<dummyPidData/>', // dummy for UAT
    };
    final response = await _dio.post('/api/dmt/sender/register', data: payload);
    return response.data;
  }
  
Future<dynamic> sendOTP(String mobile, String name) async {
  print('📱 sendOTP called with mobile: $mobile, name: $name');
  final loc = await _getLocation();
  final payload = {
    'senderMobile': mobile,
    'senderName': name,
    'ip': loc['ip'],
    'lat': loc['lat'],
    'long': loc['long'],
  };
  print('📤 Sending OTP request payload: $payload');
  try {
    final response = await _dio.post('/api/dmt/sender/retrigger-otp', data: payload);
    print('📥 OTP response data: ${response.data}');
    return response.data;
  } catch (e) {
    print('❌ OTP request failed: $e');
    rethrow;
  }
}

  Future<dynamic> verifyOTP(String mobile, String otpPin) async {
    final loc = await _getLocation();
    final response = await _dio.post(
      '/api/dmt/sender/verify-otp',
      data: {
        'senderMobile': mobile,
        'otpPin': otpPin,
        'ip': loc['ip'],
        'lat': loc['lat'],
        'long': loc['long'],
      },
    );
    return response.data;
  }

  Future<dynamic> checkSender(String mobile) async {
    final response = await _dio.post(
      '/api/dmt/beneficiary/list',
      data: {
        'senderMobileNo': mobile,
        'pageNumber': 1,
        'pageSize': 10,
      },
    );
    return response.data;
  }


Future<dynamic> getBeneficiaryList(String senderMobile, {int pageNumber = 1, int pageSize = 10}) async {
    final loc = await _getLocation();
    final response = await _dio.post('/api/dmt/beneficiary/list', data: {
        'senderMobileNo': senderMobile,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        'ip': loc['ip'],
        'lat': loc['lat'],
        'long': loc['long'],
    });
    return response.data;
}



  Future<dynamic> registerBeneficiary(Map<String, dynamic> data) async {
    final loc = await _getLocation();
    final agentCode = await StorageService.getAgentCode();
    final payload = {
      ...data,
      'agentCode': agentCode,
      'ip': loc['ip'],
      'lat': loc['lat'],
      'long': loc['long'],
    };
    final response = await _dio.post('/api/dmt/beneficiary/register', data: payload);
    return response.data;
  }

  Future<dynamic> sendMoney({
    required String benneAccId,
    required String amount,
    required String otp,
    required String txnMode, // "IMPS" or "NEFT"
  }) async {
    final loc = await _getLocation();
    final response = await _dio.post(
      '/api/dmt/transaction',
      data: {
        'benneAccId': benneAccId,
        'amount': amount,
        'otp': otp,
        'txnMode': txnMode,
        'ip': loc['ip'],
        'lat': loc['lat'],
        'long': loc['long'],
      },
    );
    return response.data;
  }
}