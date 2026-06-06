class Beneficiary {
  final String? id;           // Backend generated ID
  final String name;
  final String accountNumber;
  final String ifsc;
  final String mobile;
  final String bankCode;      // Code from bank list
  final String bankName;      // For display
  final String purposeCode;
  final String purposeDesc;
  final String stateCode;
  final String stateName;
  final String paymentMode;   // 'IMPS' or 'NEFT'

  Beneficiary({
    this.id,
    required this.name,
    required this.accountNumber,
    required this.ifsc,
    required this.mobile,
    required this.bankCode,
    required this.bankName,
    required this.purposeCode,
    required this.purposeDesc,
    required this.stateCode,
    required this.stateName,
    required this.paymentMode,
  });

factory Beneficiary.fromJson(Map<String, dynamic> json) {
  return Beneficiary(
    id: json['id']?.toString(),
    name: json['name'] ?? json['account_name'] ?? '',           // ← both
    accountNumber: json['accountNumber'] ?? json['account_number'] ?? '',
    ifsc: json['ifsc'] ?? json['ifsc_code'] ?? '',
    mobile: json['mobile'] ?? '',
    bankCode: json['bankCode'] ?? json['bank_code'] ?? '',
    bankName: json['bankName'] ?? json['bank_name'] ?? '',
    purposeCode: json['purposeCode'] ?? json['purpose_code'] ?? '',
    purposeDesc: json['purposeDesc'] ?? json['purpose_desc'] ?? '',
    stateCode: json['stateCode'] ?? json['state'] ?? '',        // backend uses 'state'
    stateName: json['stateName'] ?? json['state'] ?? '',
    paymentMode: json['paymentMode'] ?? json['payment_mode'] ?? 'IMPS',
  );
}

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'accountNumber': accountNumber,
    'ifsc': ifsc,
    'mobile': mobile,
    'bankCode': bankCode,
    'bankName': bankName,
    'purposeCode': purposeCode,
    'purposeDesc': purposeDesc,
    'stateCode': stateCode,
    'stateName': stateName,
    'paymentMode': paymentMode,
  };
}