// Bank Model
class Bank {
  final String code;
  final String name;
  final String? iin;  // ✅ Add IIN field


  // final String description;
  
  Bank({required this.code, required this.name, this.iin});
  
  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      code: json['code']?.toString() ?? '',
      // description: json['description']?.toString() ?? '',
      name: json['name'] ?? '',
      iin: json['iin'] ?? '',
    );
  }

  String? operator [](String other) {}
}

// State Model
// class AepsStateModel   {
//   final String code;
//   final String name;
  
//   AepsStateModel  ({required this.code, required this.name});
  
//   factory AepsStateModel  .fromJson(Map<String, dynamic> json) {
//     return AepsStateModel  (
//       code: json['code']?.toString() ?? '',
//       name: json['name']?.toString() ?? '',
//     );
//   }
// }

class AepsStateModel {
  final String stateId;
  final String name;
  final String code;
  final String numericCode;  // add this

  AepsStateModel({required this.stateId, required this.name, required this.code, required this.numericCode});

factory AepsStateModel.fromJson(Map<String, dynamic> json) {
    return AepsStateModel(
      // Ensure these keys match your Node.js response EXACTLY
      stateId: (json['stateId'] ?? json['id'] ?? '').toString(), 
      name: (json['name'] ?? json['stateName'] ?? '').toString(),
      code: (json['code'] ?? json['stateCode'] ?? '').toString(),
      numericCode: json['numericCode'] ?? json['code'] ?? '',

    );
  }
}



// District Model
class District {
  final String code;
  final String name;
  
  District({required this.code, required this.name});
  
  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

// Merchant Registration Request
class MerchantRegistrationRequest {
  final String firstName;
  final String middleName;
  final String lastName;
  final String dob;               // DD-MM-YYYY
  final String emailId;
  final String mobileNo;          // will become merchantPhoneNumber in JSON
  final String aadhaarNo;
  final String panNo;
  final String merchantAddress1;
  final String merchantAddress2;
  final String merchantState;     // abbreviation (e.g., "DL")
  final String merchantDistrict;  // abbreviation
  final String merchantPinCode;
  final String shopPan;
  final String bankAccountNumber;
  final String bankIfscCode;
  final String bankName;          // bank code from list
  final String accountType;
  final String shopAddress;
  final String shopDistrict;
  final String shopState;
  final String shopPinCode;
  final double shopLat;
  final double shopLong;
  final double lat;
  final double long;
  final String ipAddress;
  final String merchantRefId;
  final String pipe;
  final String gender;
  
  // var stateCode;
  
  // var districtCode;
  
  // var latitude;

  // Constructor, toJson()...

  
  MerchantRegistrationRequest({
    required this.firstName,
    required this.lastName,
    required this.emailId,
    required this.mobileNo,
    required this.aadhaarNo,
    required this.panNo,
    required this.shopAddress,
    required this.gender,
    // required this.stateCode,
    // required this.districtCode,
    required this.shopLat,
    required this.shopLong, required this.middleName, required this.dob, required this.merchantAddress1, required this.merchantAddress2, required this.merchantState, required this.merchantDistrict, required this.merchantPinCode, required this.shopPan, required this.bankAccountNumber, required this.bankIfscCode, required this.bankName, required this.accountType, required this.shopDistrict, required this.shopState, required this.shopPinCode, required this.lat, required this.long, required this.ipAddress, required this.merchantRefId, required this.pipe,
  });
  
Map<String, dynamic> toJson() => {
  "firstName": firstName,
  "middleName": middleName,
  "lastName": lastName,
  "dob": dob,
  "emailId": emailId,
  "mobileNo": mobileNo,
  "aadhaarNo": aadhaarNo,
  "panNo": panNo,
  "merchantAddress1": merchantAddress1,
  "merchantAddress2": merchantAddress2,
  "merchantState": merchantState,
  "merchantDistrict": merchantDistrict,
  "merchantPinCode": merchantPinCode,
  "shopPan": shopPan,
  "bankAccountNumber": bankAccountNumber,
  "bankIfscCode": bankIfscCode,
  "bankName": bankName,
  "accountType": accountType,
  "shopAddress": shopAddress,
  "shopDistrict": shopDistrict,
  "shopState": shopState,
  "shopPinCode": shopPinCode,
  "shopLat": shopLat,
  "shopLong": shopLong,
  "lat": lat,
  "long": long,
  "ipAddress": ipAddress,
  "merchantRefId": merchantRefId,
  "pipe": pipe,
  "gender": gender,

};
}

// AEPS Transaction Request
class AepsTransactionRequest {
  final String transactionType;
  final String amount;
  final String aadhaarNumber;
  final String bankIIN;
  final String merchantId;
  final String mobileNo;
  final String ipAddress;
  final String pidData;
  final String pipe;
  final String merchantRefId;
  final String deviceType;

  AepsTransactionRequest({
    required this.transactionType,
    required this.amount,
    required this.aadhaarNumber,
    required this.bankIIN,
    required this.merchantId,
    required this.mobileNo,
    required this.ipAddress,
    required this.pidData,
    required this.pipe,
    required this.merchantRefId,
    required this.deviceType,
  });

  Map<String, dynamic> toJson() {
    final body = {
      // ✅ Match EXACTLY what your backend controller expects
      'serviceType':    transactionType,   // backend reads req.body.serviceType
      'merchantId':     merchantId,        // backend reads req.body.merchantId
      'aadhaarNumber':  aadhaarNumber,     // backend reads req.body.aadhaarNumber
      'bankIIN':        bankIIN,           // backend reads req.body.bankIIN
      'pidData':        pidData,           // backend reads req.body.pidData
      'mobileNo':       mobileNo,
      'amount':         amount,
      'deviceType':     deviceType,
      'merchantRefId':  merchantRefId,
      'ipAddress':      ipAddress,
      'pipe':           pipe,
      'latitude':       '0',
      'longitude':      '0',
      'udf1':           '',
      'udf2':           '',
      'udf3':           '',
    };
        print('\n📦 toJson() body:');
    body.forEach((k, v) => print('   $k: $v'));
    return body;
  }
}

 
// Transaction Response
class TransactionResponse {
  final String status;
  final String? statusDescription;
  final String? rrn;
  final String? txnRefId;
  final String? availableBalance;
  final String? npciMessage;
  final String? responseCode;

  TransactionResponse({
    required this.status,
    this.statusDescription,
    this.rrn,
    this.txnRefId,
    this.availableBalance,
    this.npciMessage,
    this.responseCode,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    return TransactionResponse(
      status: json['status']?.toString() ?? json['responseCode']?.toString() ?? '',
      statusDescription: json['statusDescription'] ?? json['message'],
      rrn: json['rrn']?.toString(),
      txnRefId: json['txnRefId']?.toString(),
      availableBalance: json['availableBalance']?.toString(),
      npciMessage: json['npciMessage']?.toString(),
      responseCode: json['responseCode']?.toString(),
    );
  }
}


  
