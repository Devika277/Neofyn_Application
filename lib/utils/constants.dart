class AppConstants {
  // Service Types
  static const String serviceCashWithdrawal = 'CW';
  static const String serviceBalanceEnquiry = 'BE';
  static const String serviceMiniStatement = 'MS';
  static const String serviceAadhaarPay = 'AP';
  
  // Gender Codes
  static const String genderMale = 'M';
  static const String genderFemale = 'F';
  static const String genderOther = 'O';
  
  // Device Types
  static const String deviceTypeBiometric = 'mantra';
  static const String deviceTypeFace = 'aadhaarfacerd';
  
  // Regular Expressions
  static final RegExp aadhaarRegex = RegExp(r'^[0-9]{12}$');
  static final RegExp mobileRegex = RegExp(r'^[0-9]{10}$');
  static final RegExp panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
  static final RegExp amountRegex = RegExp(r'^[0-9]+\.?[0-9]{0,2}$');
  
  // Cache Keys
  static const String keyMerchantId = 'merchant_id';
  static const String keyMerchantRefId = 'merchant_ref_id';
  static const String keyMobileNo = 'mobile_no';
  static const String keyAadhaarNo = 'aadhaar_no';
  
  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration locationTimeout = Duration(seconds: 10);
}