import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart'; // Add uuid package


class AepsService {
  static const _channel = MethodChannel('com.yourapp/aeps');

  // UAT credentials — fetched from your Node.js backend ideally
  

  /// txnCode: 'BE' = Balance Enquiry, 'MS' = Mini Statement,
  ///          'CW' = Cash Withdrawal, 'AP' = Aadhaar Pay
  static Future<Map<String, dynamic>> launchTransaction({
    required String merchantId,
    required String txnCode,
    required String amount,
    required String lat,
    required String lng,
  }) async {
    try {

        // Generate unique reference as required [cite: 261]
        final String merchantRefId = const Uuid().v4().replaceAll('-', '');
      
        final result = await _channel.invokeMethod('launchAePS', {
        // 'secretKey': _secretKey,
        // 'saltKey': _saltKey,
        // 'encryptDecryptKey': _encryptDecryptKey,
        // 'userId': _userId,
        'merchantId': merchantId,
        'pipe': '1',                    // UAT = always 1
        'txnCode': txnCode,
        'transactionAmount': amount,
        'lat': lat,
        'long': lng,
        'merchantRefId': merchantRefId,
      });
      return {'success': true, 'data': result};
    } on PlatformException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }
}