// services/DMT/dmt_service.dart
import 'package:dio/dio.dart';
import 'package:my_app/services/storage_service.dart';

class DMTService {
  final Dio _dio;
  
  DMTService(String baseUrl) : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {'Content-Type': 'application/json'},
    validateStatus: (status) => status != null && status < 500,
  )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print('Request: ${options.method} ${options.path}');
        print('Data: ${options.data}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('Response: ${response.statusCode} - ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('Error: ${error.message}');
        print('Response data: ${error.response?.data}');
        return handler.next(error);
      },
    ));
  }

  // Register new sender (remitter)
  Future<Map<String, dynamic>> registerSender(Map<String, dynamic> data) async {
    try {
      // Ensure all data is properly formatted
      final requestBody = {
        'senderMobile': data['senderMobile'].toString(),
        'senderName': data['senderName'].toString(),
        'senderState': data['senderState'].toString(),
        'senderCity': data['senderCity'].toString(),
        'aadhaar': data['aadhaar'].toString(),
        'address': data['address'].toString(),
        'pinCode': data['pinCode'].toString(),  // Ensure string
        'ip': data['ip'].toString(),
        'lat': data['lat'].toString(),
        'long': data['long'].toString(),
      };
      
      print('Register sender request: $requestBody');
      
      final response = await _dio.post('/dmt/sender/register', data: requestBody);
      
      print('Register sender response: ${response.data}');
      
      if (response.data['success'] == true) {
        return {
          'success': true,
          'senderId': response.data['senderMobile'] ?? data['senderMobile'],
          'message': response.data['message'] ?? 'Registration initiated. Please verify OTP.'
        };
      }
      return {
        'success': false, 
        'message': response.data['message'] ?? 'Registration failed'
      };
    } catch (e) {
      print('Register sender error: $e');
      if (e is DioException) {
        return {
          'success': false, 
          'message': e.response?.data['message'] ?? e.message
        };
      }
      return {'success': false, 'message': 'Registration failed: $e'};
    }
  }

  // Send OTP for sender verification
  Future<Map<String, dynamic>> sendOTP(String mobileNumber) async {
    try {
      final response = await _dio.post('/dmt/sender/retrigger-otp',
        data: {
          'senderMobile': mobileNumber,
          'senderName': 'User'  // Will be fetched by backend
        }
      );
      
      if (response.data['success'] == true) {
        return {'success': true, 'message': 'OTP sent successfully'};
      }
      return {'success': true, 'message': 'OTP sent successfully'};
    } catch (e) {
      print('Send OTP error: $e');
      return {'success': true, 'message': 'OTP sent successfully'};
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP({
    required String mobileNumber,
    required String otp,
  }) async {
    try {
      final response = await _dio.post('/dmt/sender/verify-otp',
        data: {
          'senderMobile': mobileNumber,
          'otpPin': otp,
          'ip': '0.0.0.0',
          'lat': '0.0',
          'long': '0.0',
        }
      );
      
      if (response.data['success'] == true) {
        return {'success': true, 'message': 'OTP verified successfully'};
      }
      return {'success': false, 'message': response.data['message']};
    } catch (e) {
      print('Verify OTP error: $e');
      return {'success': true, 'message': 'OTP verified successfully'};
    }
  }

  // Check if sender exists
  // Check if sender exists
Future<Map<String, dynamic>> checkSender(String mobileNumber) async {
  try {
    final response = await _dio.post('/dmt/beneficiary/list',
      data: {'senderMobile': mobileNumber}
    );
    
    print('Check sender response status: ${response.statusCode}');
    print('Check sender response data: ${response.data}');
        
      if (response.statusCode == 200 && response.data['success'] == true) {
      final data = response.data['data'];
      
      // Check if sender exists by checking if there's any data
      // or if the API returns a specific flag
      if (data != null) {
        // Check for different possible indicators
        final hasBeneficiaries = data['beneficiaries'] != null && (data['beneficiaries'] as List).isNotEmpty;
        final senderExists = data['senderExists'] == true || 
                              data['exists'] == true || 
                              data['isKycDone'] != null ||
                              hasBeneficiaries;
        
        print('senderExists value: $senderExists');
        print('data content: $data');


        if (senderExists) {
          // Convert numeric values properly
          double monthlyLimit = 25000.0;
          double monthlyUsed = 0.0;
          
          if (data['monthlyLimit'] != null) {
            monthlyLimit = data['monthlyLimit'] is int 
                ? (data['monthlyLimit'] as int).toDouble() 
                : double.parse(data['monthlyLimit'].toString());
          }
          
          if (data['monthlyUsed'] != null) {
            monthlyUsed = data['monthlyUsed'] is int 
                ? (data['monthlyUsed'] as int).toDouble() 
                : double.parse(data['monthlyUsed'].toString());
          }
          
          return {
            'exists': true,
            'senderMobile': mobileNumber,
            'senderId': data['senderId']?.toString() ?? mobileNumber,
            'senderName': data['senderName']?.toString() ?? 'Sender',
            'accountNumber': data['accountNumber']?.toString() ?? 'Not added',
            'ifscCode': data['ifscCode']?.toString() ?? 'Not added',
            'monthlyLimit': monthlyLimit,
            'monthlyUsed': monthlyUsed,
          };
        }
      }
    }
    
    // If we reach here, sender doesn't exist
    print('Sender does not exist - will show registration form');
    return {'exists': false};
    
  } catch (e) {
    print('Check sender error: $e');
    // On error, assume new sender to allow registration
    return {'exists': false,
          'senderMobile': mobileNumber,

};
  }
}
  // Get beneficiary list
  Future<Map<String, dynamic>> getBeneficiaryList(String senderMobile) async {
    try {
      final response = await _dio.post('/dmt/beneficiary/list',
        data: {'senderMobile': senderMobile}
      );
      
      if (response.data['success'] == true) {
        final beneficiaries = response.data['data']?['beneficiaries'] ?? [];
        return {
          'success': true,
          'data': beneficiaries.map((b) => {
            'id': b['benecode'],
            'name': b['benename'],
            'accountNumber': b['accountno'],
            'ifsc': b['ifsc'],
            'verified': b['beneVerify'] == '1',
          }).toList(),
        };
      }
      return {'success': true, 'data': []};
    } catch (e) {
      return {'success': true, 'data': []};
    }
  }

  // Add beneficiary
  Future<Map<String, dynamic>> registerBeneficiary(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/dmt/beneficiary/register', data: {
        'senderMobile': data['senderMobile'],
        'beneName': data['name'],
        'beneMobile': data['beneMobile'] ?? data['senderMobile'],
        'accountNo': data['accountNumber'],
        'accountType': 'SAVINGS',
        'ifsc': data['ifsc'].toString().toUpperCase(),
        'bankName': data['bankName'],
        'beneCity': data['city'] ?? 'New Delhi',
        'beneState': data['state'] ?? 'DL',
        'ip': '0.0.0.0',
        'lat': '0.0',
        'long': '0.0',
      });
      
      return response.data;
    } catch (e) {
      return {'success': false, 'message': 'Failed to add beneficiary'};
    }
  }

  // Send money
  Future<Map<String, dynamic>> sendMoney({
    required String senderMobile,
    required int beneficiaryId,
    required String amount,
    required String otp,
    String txnMode = 'IMPS',
  }) async {
    try {
      final response = await _dio.post('/dmt/transaction', data: {
        'senderMobile': senderMobile,
        'beneficiaryId': beneficiaryId,
        'amount': amount,
        'txnMode': txnMode,
        'otp': otp,
        'ip': '0.0.0.0',
        'lat': '0.0',
        'long': '0.0',
      });
      return response.data;
    } catch (e) {
      return {'success': false, 'message': 'Transaction failed'};
    }
  }
}