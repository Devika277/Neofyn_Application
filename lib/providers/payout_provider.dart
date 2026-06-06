// lib/providers/payout_provider.dart
import 'package:flutter/material.dart';
import '../services/Payout/payout_service.dart';
// import '../models/payout_request.dart';

// Helper models for dropdowns (define these if not already in separate files)
class BankModel {
  final String code;
  final String description;
  BankModel({required this.code, required this.description});
  factory BankModel.fromJson(Map<String, dynamic> json) => BankModel(
        code: json['code']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
      );
}

class PurposeModel {
  final String code;
  final String description;
  PurposeModel({required this.code, required this.description});
  factory PurposeModel.fromJson(Map<String, dynamic> json) => PurposeModel(
        code: json['code']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
      );
}

class StateModel {
  final String code;
  final String description;
  StateModel({required this.code, required this.description});
  factory StateModel.fromJson(Map<String, dynamic> json) => StateModel(
        code: json['code']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
      );
}

class PayoutProvider extends ChangeNotifier {
  final PayoutService _payoutService = PayoutService();
  
  // State variables
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Guards to prevent multiple master data loads
  bool _isLoadingMaster = false;
  bool _masterDataLoaded = false;
  
  // Master data
  List<BankModel> _banks = [];
  List<PurposeModel> _purposes = [];
  List<StateModel> _states = [];
  
  // Selected values
  String? _selectedBankCode;
  String? _selectedPurposeCode;
  String? _selectedStateCode;
  String? _selectedPaymentMode;
  
  // Balance (optional, commented out if not used)
  double _balance = 0.0;
  
  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<BankModel> get banks => _banks;
  List<PurposeModel> get purposes => _purposes;
  List<StateModel> get states => _states;
  String? get selectedBankCode => _selectedBankCode;
  String? get selectedPurposeCode => _selectedPurposeCode;
  String? get selectedStateCode => _selectedStateCode;
  String? get selectedPaymentMode => _selectedPaymentMode;
  double get balance => _balance;
  
  // ✅ Load master data only once, prevent concurrent calls
  Future<void> loadMasterData() async {
    // Guard: already loading or already loaded
    if (_isLoadingMaster || _masterDataLoaded) {
      debugPrint('⚠️ loadMasterData skipped: already loading or loaded');
      return;
    }
    
    _isLoadingMaster = true;
    _isLoading = true;  // Show global loading if needed
    _clearError();
    notifyListeners();
    
    try {
      debugPrint('🔄 Loading master data (banks, purposes, states)...');
      
      // Load all master data in parallel (no balance call - causes index mismatch)
      final results = await Future.wait([
        _payoutService.getBankList(),
        _payoutService.getPurposeList(),
        _payoutService.getStateList(),
      ]);
      
      // Parse banks (index 0)
      if (results[0]['success'] == true && results[0]['data'] != null) {
        _banks = (results[0]['data'] as List)
            .map((item) => BankModel.fromJson(item))
            .toList();
        debugPrint('✅ Banks loaded: ${_banks.length}');
      } else {
        debugPrint('❌ Banks failed: ${results[0]['message']}');
      }
      
      // Parse purposes (index 1)
      if (results[1]['success'] == true && results[1]['data'] != null) {
        _purposes = (results[1]['data'] as List)
            .map((item) => PurposeModel.fromJson(item))
            .toList();
        debugPrint('✅ Purposes loaded: ${_purposes.length}');
      } else {
        debugPrint('❌ Purposes failed: ${results[1]['message']}');
      }
      
      // Parse states (index 2)
      if (results[2]['success'] == true && results[2]['data'] != null) {
        _states = (results[2]['data'] as List)
            .map((item) => StateModel.fromJson(item))
            .toList();
        debugPrint('✅ States loaded: ${_states.length}');
      } else {
        debugPrint('❌ States failed: ${results[2]['message']}');
      }
      
      _masterDataLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ loadMasterData error: $e');
      _setError(e.toString());
    } finally {
      _isLoadingMaster = false;
      _isLoading = false;
      notifyListeners();
    }
  }
  

  Future<List<dynamic>> getTransactionHistory() async {
  _isLoading = true;
  _clearError();
  notifyListeners();
  try {
    return await _payoutService.getTransactionHistory();
  } catch (e) {
    _setError(e.toString());
    return [];
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<Map<String, dynamic>> getTransactionStatus(String merchantRefId) async {
  _isLoading = true;
  _clearError();
  notifyListeners();
  try {
    return await _payoutService.getTransactionStatus(merchantRefId);
  } catch (e) {
    _setError(e.toString());
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
  // Setters for selections
  void setSelectedBank(String code) {
    _selectedBankCode = code;
    notifyListeners();
  }
  
  void setSelectedPurpose(String code) {
    _selectedPurposeCode = code;
    notifyListeners();
  }
  
  void setSelectedState(String code) {
    _selectedStateCode = code;
    notifyListeners();
  }
  
  void setSelectedPaymentMode(String mode) {
    _selectedPaymentMode = mode;
    notifyListeners();
  }
  
  // Get descriptive names from codes
  String getBankName(String code) {
    final bank = _banks.firstWhere((b) => b.code == code, orElse: () => BankModel(code: '', description: ''));
    return bank.description;
  }
  
  String getPurposeName(String code) {
    final purpose = _purposes.firstWhere((p) => p.code == code, orElse: () => PurposeModel(code: '', description: ''));
    return purpose.description;
  }
  
  String getStateName(String code) {
    final state = _states.firstWhere((s) => s.code == code, orElse: () => StateModel(code: '', description: ''));
    return state.description;
  }
  
  // Initiate payout
  Future<Map<String, dynamic>> initiatePayout(Map<String, dynamic> payoutData) async {
    _isLoading = true;
    _clearError();
    notifyListeners();
    
    try {
      final response = await _payoutService.initiatePayout(payoutData);
      return response;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = '';
    notifyListeners();
  }
  
  void clearSelections() {
    _selectedBankCode = null;
    _selectedPurposeCode = null;
    _selectedStateCode = null;
    _selectedPaymentMode = null;
    notifyListeners();
  }
  
  // Optional: reset entire state (useful for logout)
  void reset() {
    _banks = [];
    _purposes = [];
    _states = [];
    _selectedBankCode = null;
    _selectedPurposeCode = null;
    _selectedStateCode = null;
    _selectedPaymentMode = null;
    _errorMessage = '';
    _masterDataLoaded = false;
    _isLoadingMaster = false;
    _isLoading = false;
    notifyListeners();
  }
}

