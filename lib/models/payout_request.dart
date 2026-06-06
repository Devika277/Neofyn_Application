// lib/models/payout_models.dart
class BankModel {
  final String code;
  final String description;
  
  BankModel({required this.code, required this.description});
  
  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      code: json['code'].toString(),
      description: json['description'],
    );
  }
}

class PurposeModel {
  final String code;
  final String description;
  
  PurposeModel({required this.code, required this.description});
  
  factory PurposeModel.fromJson(Map<String, dynamic> json) {
    return PurposeModel(
      code: json['code'].toString(),
      description: json['description'],
    );
  }
}

class StateModel {
  final String code;
  final String description;
  
  StateModel({required this.code, required this.description});
  
  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      code: json['code'],
      description: json['description'],
    );
  }
}

class PayoutRequest {
  final double amount;
  final String merchantRefId;
  final String beneficiaryBank;
  final String paymentPurpose;
  final String paymentMode;
  final String beneficiaryAccountNumber;
  final String beneficiaryIFSC;
  final String beneficiaryMobileNumber;
  final String beneficiaryName;
  final String beneficiaryLocation;
  final String lat;
  final String lon;
  final String udf1;
  final String udf2;
  final String udf3;
  
  PayoutRequest({
    required this.amount,
    required this.merchantRefId,
    required this.beneficiaryBank,
    required this.paymentPurpose,
    required this.paymentMode,
    required this.beneficiaryAccountNumber,
    required this.beneficiaryIFSC,
    required this.beneficiaryMobileNumber,
    required this.beneficiaryName,
    required this.beneficiaryLocation,
    this.lat = '0',
    this.lon = '0',
    this.udf1 = '',
    this.udf2 = '',
    this.udf3 = '',
  });
  
  Map<String, dynamic> toJson() => {
    'amount': amount,
    'merchantRefId': merchantRefId,
    'beneficiaryBank': beneficiaryBank,
    'paymentPurpose': paymentPurpose,
    'paymentMode': paymentMode,
    'beneficiaryAccountNumber': beneficiaryAccountNumber,
    'beneficiaryIFSC': beneficiaryIFSC,
    'beneficiaryMobileNumber': beneficiaryMobileNumber,
    'beneficiaryName': beneficiaryName,
    'beneficiaryLocation': beneficiaryLocation,
    'lat': lat,
    'long': lon,
    'udf1': udf1,
    'udf2': udf2,
    'udf3': udf3,
  };
}

class PayoutResponse {
  final bool success;
  final String message;
  final String? responseCode;
  final PayoutData? data;
  
  PayoutResponse({
    required this.success,
    required this.message,
    this.responseCode,
    this.data,
  });
  
  factory PayoutResponse.fromJson(Map<String, dynamic> json) {
    return PayoutResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      responseCode: json['responseCode'],
      data: json['data'] != null ? PayoutData.fromJson(json['data']) : null,
    );
  }
}

class PayoutData {
  final String txnStatus;
  final String txnStatusCode;
  final String responseMessage;
  final String txnId;
  final String amount;
  final String paymentMode;
  final String merchantRefId;
  
  PayoutData({
    required this.txnStatus,
    required this.txnStatusCode,
    required this.responseMessage,
    required this.txnId,
    required this.amount,
    required this.paymentMode,
    required this.merchantRefId,
  });
  
  factory PayoutData.fromJson(Map<String, dynamic> json) {
    return PayoutData(
      txnStatus: json['txnStatus'] ?? '',
      txnStatusCode: json['txnStatusCode'] ?? '',
      responseMessage: json['responseMessage'] ?? '',
      txnId: json['txnId'] ?? '',
      amount: json['amount']?.toString() ?? '0',
      paymentMode: json['paymentMode'] ?? '',
      merchantRefId: json['merchantRefId'] ?? '',
    );
  }
}