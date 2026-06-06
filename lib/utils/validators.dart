import 'constants.dart';

class Validators {
  // Validate Aadhaar Number
  static String? validateAadhaar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Aadhaar number is required';
    }
    if (!AppConstants.aadhaarRegex.hasMatch(value)) {
      return 'Enter valid 12-digit Aadhaar number';
    }
    return null;
  }
  
  // Validate Mobile Number
  static String? validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }
    if (!AppConstants.mobileRegex.hasMatch(value)) {
      return 'Enter valid 10-digit mobile number';
    }
    return null;
  }
  
  // Validate PAN Card
  static String? validatePAN(String? value) {
    if (value == null || value.isEmpty) {
      return null; // PAN is optional
    }
    if (!AppConstants.panRegex.hasMatch(value.toUpperCase())) {
      return 'Enter valid PAN number (e.g., ABCDE1234F)';
    }
    return null;
  }
  
  // Validate Amount
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    if (!AppConstants.amountRegex.hasMatch(value)) {
      return 'Enter valid amount';
    }
    final amount = double.parse(value);
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    if (amount > 50000) {
      return 'Amount cannot exceed ₹50,000 per transaction';
    }
    return null;
  }
  
  // Validate Email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter valid email address';
    }
    return null;
  }
  
  // Validate Name
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (value.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (value.length > 50) {
      return '$fieldName cannot exceed 50 characters';
    }
    return null;
  }
  
  // Validate OTP
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    return null;
  }
  
  // Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  // Validate PIN code
  static String? validatePincode(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional
    }
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
      return 'Enter valid 6-digit PIN code';
    }
    return null;
  }
}