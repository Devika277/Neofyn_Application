import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemitterProvider extends ChangeNotifier {
  bool _isRegistered = false;
  String? _remitterPhone;
  Map<String, dynamic>? _remitterData;

  bool get isRegistered => _isRegistered;
  String? get remitterPhone => _remitterPhone;

  Future<bool> checkRemitter(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString('remitter_phone');
      if (savedPhone == phone) {
        _isRegistered = true;
        _remitterPhone = phone;
        notifyListeners();
        return true;
      } else {
        _isRegistered = false;
        _remitterPhone = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print("checkRemitter error: $e");
      _isRegistered = false;
      _remitterPhone = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> registerRemitter(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('remitter_phone', data['mobile']);
    await prefs.setString('remitter_name', data['name']);
    _isRegistered = true;
    _remitterPhone = data['mobile'];
    _remitterData = data;
    notifyListeners();
  }
}