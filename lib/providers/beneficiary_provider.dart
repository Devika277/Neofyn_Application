import 'package:flutter/material.dart';
import '../services/Payout/payout_service.dart';
import '../models/beneficiary_model.dart';

class BeneficiaryProvider extends ChangeNotifier {
  final PayoutService _payoutService = PayoutService();
  List<Beneficiary> _beneficiaries = [];
  bool _isLoading = false;
  String _error = '';

  List<Beneficiary> get beneficiaries => _beneficiaries;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> loadBeneficiaries() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      _beneficiaries = await _payoutService.getBeneficiaries();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBeneficiary(Beneficiary beneficiary) async {
    _isLoading = true;
    notifyListeners();
    try {
      final saved = await _payoutService.saveBeneficiary(beneficiary);
      _beneficiaries.add(saved);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteBeneficiary(String id) async {
    await _payoutService.deleteBeneficiary(id);
    _beneficiaries.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

Future<void> updateBeneficiary(Beneficiary beneficiary) async {
  _isLoading = true;
  notifyListeners();
  try {
    final saved = await _payoutService.saveBeneficiary(beneficiary);
    final index = _beneficiaries.indexWhere((b) => b.id == saved.id);
    if (index != -1) _beneficiaries[index] = saved;
  } catch (e) {
    _error = e.toString();
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
}