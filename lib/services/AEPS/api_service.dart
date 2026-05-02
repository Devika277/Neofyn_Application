import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const baseUrl = 'https://kinsman-borax-colony.ngrok-free.dev/api';

  // ─── User Session ───────────────────────────────────────────────────────────
  // ✅ Read userId as STRING (matches your login screen which saves as String)

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId'); // ✅ String not int
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name') ?? 'User';
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ─── AUTH ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(
      String phone, String password) async {
    try {
      debugPrint('POST → $baseUrl/auth/login');
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers(),
        body: jsonEncode({'phone': phone, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      debugPrint('Login response: ${res.body}');
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('Login error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> register(
      String name, String phone, String password) async {
    try {
      debugPrint('POST → $baseUrl/auth/register');
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers(),
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint('Register response: ${res.body}');
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('Register error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── MASTER DATA ────────────────────────────────────────────────────────────

  static Future<List> getBanks() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/master/banks'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);
      return data['banks'] ?? [];
    } catch (e) {
      debugPrint('getBanks error: $e');
      return [];
    }
  }

  static Future<List> getStates() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/master/states'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);
      return data['states'] ?? [];
    } catch (e) {
      debugPrint('getStates error: $e');
      return [];
    }
  }

  static Future<List> getDistricts(String stateCode) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/master/districts'),
        headers: _headers(),
        body: jsonEncode({'stateCode': stateCode}),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);
      return data['districts'] ?? [];
    } catch (e) {
      debugPrint('getDistricts error: $e');
      return [];
    }
  }

  // ─── MERCHANT ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getMerchantStatus() async {
    try {
      final userId = await getUserId();
      debugPrint('Checking merchant status for userId: $userId');

      if (userId == null || userId.isEmpty) {
        return {'registered': false, 'merchantId': null};
      }

      final res = await http.get(
        Uri.parse('$baseUrl/merchant/status/$userId'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 15));

      debugPrint('Merchant status: ${res.body}');
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('getMerchantStatus error: $e');
      return {'registered': false, 'merchantId': null};
    }
  }

  static Future<Map<String, dynamic>> registerMerchant(
      Map<String, dynamic> payload) async {
    try {
      final userId = await getUserId();
      final token = await getAccessToken();

      if (userId == null || userId.isEmpty) {
        return {'success': false, 'error': 'User not logged in'};
      }

      debugPrint('POST → $baseUrl/merchant/register');

      final res = await http.post(
        Uri.parse('$baseUrl/merchant/register'),
        headers: {
          ..._headers(),
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          ...payload,
          'userId': userId, // ✅ String userId — matches your login save
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('Register merchant response: ${res.body}');
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('registerMerchant error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

static Future<void> saveTransaction(Map<String, dynamic> responseJson) async {
    try {
      final userId = await getUserId();
      final token = await getAccessToken();

      // Explicitly format data according to SDK standards
      final Map<String, dynamic> body = {
        'userId': userId,
        'merchantId': responseJson['merchantId'],
        'merchantRefId': responseJson['merchantRefId']?.toString() ?? '',
        'txnRefId': responseJson['txnRefId']?.toString() ?? '',
        'txnType': responseJson['txnType'], 
        'amount': responseJson['transactionAmount']?.toString() ?? '0',
        'aadhaarNo': responseJson['aadhaarNo']?.toString() ?? '',
        'bankIIN': responseJson['bankIIN']?.toString() ?? '',
        // Force RRN to String to preserve leading zeros
        'rrn': responseJson['rrn']?.toString() ?? '', 
        'npciCode': responseJson['npciCode']?.toString() ?? '',
        'npciMessage': responseJson['npciMessage']?.toString() ?? '',
        // Force Balance to String to keep decimal precision
        'availableBalance': responseJson['availableBalance']?.toString() ?? '0.00',
        'status': responseJson['merchantStatus'] ?? '',
        'txnDateTime': responseJson['txnDateTime']?.toString() ?? '',
        'pipe': responseJson['pipe']?.toString() ?? '1',
      };

      debugPrint('Saving Transaction to Node.js: ${jsonEncode(body)}');

      final res = await http.post(
        Uri.parse('$baseUrl/merchant/transaction'),
        headers: {
          ..._headers(),
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      debugPrint('Save Transaction Response: ${res.statusCode}');
    } catch (e) {
      debugPrint('saveTransaction error: $e');
    }
  }

  static Future<List> getTransactionHistory() async {
    try {
      final userId = await getUserId();
      if (userId == null || userId.isEmpty) return [];

      final res = await http.get(
        Uri.parse('$baseUrl/merchant/transactions/$userId'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);
      return data['transactions'] ?? [];
    } catch (e) {
      debugPrint('getTransactionHistory error: $e');
      return [];
    }
  }

  // ─── Private Helper ─────────────────────────────────────────────────────────

  static Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true', // ✅ required for ngrok
  };
}