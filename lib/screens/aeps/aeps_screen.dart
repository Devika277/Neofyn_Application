import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/AEPS/aeps_service.dart';
import '../../services/AEPS/api_service.dart';
import 'package:geolocator/geolocator.dart';


class AepsScreen extends StatefulWidget {
  final String merchantId;
  const AepsScreen({required this.merchantId, super.key});

  @override
  State<AepsScreen> createState() => _AepsScreenState();
}

class _AepsScreenState extends State<AepsScreen> {
  String _status = '';
  bool _loading = false;
  Map<String, dynamic>? _lastResult;

  // Future<void> _doTransaction(String txnCode, String amount) async {
  //   setState(() {
  //     _loading = true;
  //     _status = '';
  //     _lastResult = null;
  //   });

// Future<void> _checkMerchantStatus() async {
//   try {
//     // ✅ Check what userId is stored
//     final prefs = await SharedPreferences.getInstance();
//     final userId = prefs.getString('userId');
//     debugPrint('=============================');
//     debugPrint('userId from prefs: $userId');
//     debugPrint('=============================');

//     if (userId == null || userId.isEmpty) {
//       debugPrint('❌ No userId found — user not logged in properly');
//       setState(() {
//         _isMerchantRegistered = false;
//         _merchantId = null;
//         _loading = false;
//       });
//       return;
//     }

//     final result = await ApiService.getMerchantStatus();
//     debugPrint('Merchant status result: $result');
//     debugPrint('registered value: ${result['registered']}');
//     debugPrint('registered type: ${result['registered'].runtimeType}');

//     setState(() {
//       // ✅ Force boolean check — not just truthy
//       _isMerchantRegistered = result['registered'] == true;
//       _merchantId = result['merchantId'];
//       _loading = false;
//     });

//     debugPrint('_isMerchantRegistered set to: $_isMerchantRegistered');
//   } catch (e) {
//     debugPrint('❌ _checkMerchantStatus error: $e');
//     setState(() {
//       _isMerchantRegistered = false;
//       _loading = false;
//     });
//   }
// }




  //   final result = await AepsService.launchTransaction(
  //     merchantId: widget.merchantId,
  //     txnCode: txnCode,
  //     amount: amount,
  //     lat: '10.5276',
  //     lng: '76.2144',
  //   );

  //   if (result['success']) {
  //     try {
  //       final responseStr = result['data'] as String;
  //       final responseJson = jsonDecode(responseStr);

  //       // Save to backend — userId auto-attached inside ApiService
  //       await ApiService.saveTransaction({
  //         'merchantRefId':    responseJson['merchantRefId'] ?? '',
  //         'txnRefId':         responseJson['txnRefId'] ?? '',
  //         'txnType':          txnCode,
  //         'amount':           responseJson['transactionAmount'] ?? amount,
  //         'aadhaarNo':        responseJson['aadhaarNo'] ?? '',
  //         'bankIIN':          responseJson['bankIIN'] ?? '',
  //         'rrn':              responseJson['rrn'] ?? '',
  //         'npciCode':         responseJson['npciCode'] ?? '',
  //         'npciMessage':      responseJson['npciMessage'] ?? '',
  //         'availableBalance': responseJson['availableBalance'] ?? '',
  //         'status':           responseJson['merchantStatus'] ?? '',
  //         'pipe':             responseJson['pipe'] ?? '1',
  //         'rawResponse':      responseJson,
  //       });

  //       setState(() {
  //         _lastResult = responseJson;
  //         _status = 'success';
  //       });
  //     } catch (e) {
  //       setState(() { _status = 'Error: Failed to parse response — $e'; });
  //     }
  //   } else {
  //     setState(() { _status = 'Error: ${result['error']}'; });
  //   }

  //   setState(() { _loading = false; });
  // }

Future<void> _handleTransaction(String txnCode, String amount) async {
  setState(() {
    _loading = true;
    _status = '';
    _lastResult = null;
  });

  try {
    // 1. Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled. Please enable GPS.';
    }

    // 2. Check and Request permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied.';
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied. Please enable them in settings.';
    }

    // 3. Get high-accuracy position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );

    // 4. Launch SDK with real coordinates
    final result = await AepsService.launchTransaction(
      merchantId: widget.merchantId,
      txnCode: txnCode,
      amount: amount,
      lat: position.latitude.toString(),
      lng: position.longitude.toString(),
    );

    if (result['success']) {
      final responseStr = result['data'] as String;
      final responseJson = jsonDecode(responseStr);

      // 5. Save to Node.js backend via ApiService
      await ApiService.saveTransaction({
        ...responseJson,
        'txnType': txnCode, // Explicitly pass the code used
      });

      setState(() {
        _lastResult = responseJson;
        _status = 'success';
      });
    } else {
      setState(() { _status = 'Error: ${result['error']}'; });
    }
  } catch (e) {
    setState(() { _status = 'Error: $e'; });
  } finally {
    setState(() { _loading = false; });
  }
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('AePS Transaction',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2ECC71)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Loading ──
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2ECC71)),
                    SizedBox(height: 12),
                    Text('Processing biometric...',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

            // ── Error Banner ──
            if (_status.startsWith('Error'))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_status,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),

            // ── Success Result Card ──
            if (_status == 'success' && _lastResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2ECC71)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF2ECC71)),
                        SizedBox(width: 8),
                        Text('Transaction Successful',
                            style: TextStyle(
                                color: Color(0xFF2ECC71),
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    ),
                    const Divider(color: Colors.grey),
                    _resultRow('Status',  _lastResult!['npciMessage'] ?? ''),
                    _resultRow('RRN',     _lastResult!['rrn'] ?? ''),
                    _resultRow('Balance', '₹${_lastResult!['availableBalance'] ?? ''}'),
                    _resultRow('Aadhaar', _lastResult!['aadhaarNo'] ?? ''),
                    _resultRow('Time',    _lastResult!['txnDateTime'] ?? ''),
                    if ((_lastResult!['transactionList'] ?? '').toString().isNotEmpty)
                      _resultRow('Statement', _lastResult!['transactionList']),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            // ── Transaction Buttons ──
            if (!_loading) ...[
              _txnButton(
                icon: Icons.account_balance_wallet,
                label: 'Balance Enquiry',
                color: const Color(0xFF2ECC71),
                onTap: () => _handleTransaction('BE', '0'),
              ),
              const SizedBox(height: 12),
              _txnButton(
                icon: Icons.receipt_long,
                label: 'Mini Statement',
                color: Colors.blue,
                onTap: () => _handleTransaction('MS', '0'),
              ),
              const SizedBox(height: 12),
              _txnButton(
                icon: Icons.payments,
                label: 'Cash Withdrawal',
                color: Colors.purple,
                onTap: () => _showAmountDialog('Cash Withdrawal', 'CW'),
              ),
              const SizedBox(height: 12),
              _txnButton(
                icon: Icons.fingerprint,
                label: 'Aadhaar Pay',
                color: Colors.orange,
                onTap: () => _showAmountDialog('Aadhaar Pay', 'AP'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _txnButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: color.withOpacity(0.5)),
          ),
        ),
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color, fontSize: 15)),
        onPressed: onTap,
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _showAmountDialog(String title, String txnCode) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('Enter Amount — $title',
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Amount in ₹',
            hintStyle: TextStyle(color: Colors.grey),
            prefixText: '₹ ',
            prefixStyle: TextStyle(color: Color(0xFF2ECC71)),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2ECC71))),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2ECC71))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71)),
            onPressed: () {
              final amount = ctrl.text.trim();
              Navigator.pop(context);
              if (amount.isNotEmpty) {
                _handleTransaction(txnCode, amount);
              }
            },
            child: const Text('Proceed',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}