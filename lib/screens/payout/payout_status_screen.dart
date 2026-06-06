// lib/screens/payout/payout_status_screen.dart
import 'package:flutter/material.dart';
import '../../services/Payout/payout_service.dart';
import '../payout/payout_receipt_screen.dart';


class PayoutStatusScreen extends StatefulWidget {
  final String merchantRefId;
  const PayoutStatusScreen({Key? key, required this.merchantRefId}) : super(key: key);

  @override
  State<PayoutStatusScreen> createState() => _PayoutStatusScreenState();
}

class _PayoutStatusScreenState extends State<PayoutStatusScreen> {
  final PayoutService _service = PayoutService();
  Map<String, dynamic>? _transaction;
  bool _loading = true;
  bool _isPolling = true;

  @override
  void initState() {
    super.initState();
    _fetchStatusLoop();
  }

  @override
  void dispose() {
    _isPolling = false;
    super.dispose();
  }

  Future<void> _fetchStatusLoop() async {
    while (_isPolling && mounted) {
      try {
        final response = await _service.getTransactionStatus(widget.merchantRefId);
        if (response['success'] == true) {
          final data = response['data'];
          if (mounted) {
            setState(() {
              _transaction = data;
              _loading = false;
            });
          }
          
          final status = data['status'];
          if (status == 'SUCCESS' || status == 'FAILED') {
            _isPolling = false;
            break; // Exit loop immediately
          }
        }
      } catch (e) {
        debugPrint('Status polling error: $e');
      }
      if (_isPolling) await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> _manualRefresh() async {
    setState(() => _loading = true);
    try {
      final response = await _service.getTransactionStatus(widget.merchantRefId);
      if (response['success'] == true) {
        setState(() {
          _transaction = response['data'];
          _loading = false;
        });
        final status = _transaction!['status'];
        if (status == 'SUCCESS' || status == 'FAILED') {
          _isPolling = false;
        }
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout Receipt'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transaction == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Transaction not found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _manualRefresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildReceipt(),
    );
  }

  Widget _buildReceipt() {
    final tx = _transaction!;
    final isSuccess = tx['status'] == 'SUCCESS';
    final isFailed = tx['status'] == 'FAILED';
    final isProcessing = !isSuccess && !isFailed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Shop Header
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Replace with your actual logo asset
                  Image.asset(
                    'assets/logo.png',
                    height: 60,
                    errorBuilder: (_, __, ___) => const Icon(Icons.store, size: 60),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Neofyn Payout Services',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text('Authorised Payout Partner', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Status Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle : (isFailed ? Icons.error : Icons.hourglass_empty),
                    size: 64,
                    color: isSuccess ? Colors.green : (isFailed ? Colors.red : Colors.orange),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSuccess ? 'TRANSACTION SUCCESS' : (isFailed ? 'TRANSACTION FAILED' : 'PROCESSING'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSuccess ? Colors.green : (isFailed ? Colors.red : Colors.orange),
                    ),
                  ),
                  if (isProcessing) ...[
                    const SizedBox(height: 8),
                    const Text('Your payout is being processed. Please wait or refresh.'),
                    const SizedBox(height: 12),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),


// --- NEW: VIEW RECEIPT BUTTON ---
        if (isSuccess) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PayoutReceiptScreen(
                      merchantRefId: widget.merchantRefId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long, color: Colors.white),
              label: const Text(
                'VIEW & PRINT RECEIPT',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],



          // Transaction Details Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Transaction Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _detailRow('Reference ID', tx['merchantRefId']),
                  _detailRow('Transaction ID', tx['txnId'] ?? 'Pending'),
                  _detailRow('Amount', '₹${tx['amount']}'),
                  _detailRow('Payment Mode', tx['paymentMode']),
                  _detailRow('Purpose', tx['paymentPurpose']),
                  _detailRow('Date & Time', _formatDate(tx['createdAt'])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Beneficiary Details Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Beneficiary Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _detailRow('Name', tx['beneficiaryName']),
                  _detailRow('Account Number', tx['beneficiaryAccountNumber']),
                  _detailRow('IFSC Code', tx['beneficiaryIFSC']),
                  _detailRow('Bank', tx['beneficiaryBank']),
                  _detailRow('Mobile', tx['beneficiaryMobile']),
                  _detailRow('Location', tx['beneficiaryLocation']),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Remitter (Sender) Details Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sender Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _detailRow('Name', tx['remitterName']),
                  _detailRow('Mobile', tx['remitterPhone']),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Manual Refresh Button (only visible while processing)
          if (isProcessing)
            ElevatedButton.icon(
              onPressed: _manualRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Check Status Now'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime.toString();
    }
  }
}