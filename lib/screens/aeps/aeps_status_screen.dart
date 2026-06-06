// lib/screens/aeps/aeps_status_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/AEPS/api_service.dart';
import 'aeps_receipt_screen.dart';

class AepsStatusScreen extends StatefulWidget {
  final String txnRefId;
  final String transactionType; // 'CASH_WITHDRAWAL' | 'BALANCE_ENQUIRY' | 'MINI_STATEMENT'
  final double amount;

  const AepsStatusScreen({
    Key? key,
    required this.txnRefId,
    required this.transactionType,
    this.amount = 0,
  }) : super(key: key);

  @override
  State<AepsStatusScreen> createState() => _AepsStatusScreenState();
}

class _AepsStatusScreenState extends State<AepsStatusScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _transaction;
  bool _loading = true;
  bool _isPolling = true;
  int _pollCount = 0;
  static const int _maxPolls = 20; // 60 seconds max

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startPolling();
  }

  @override
  void dispose() {
    _isPolling = false;
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startPolling() async {
    while (_isPolling && mounted && _pollCount < _maxPolls) {
      try {
        final response = await _apiService.getTransactionStatus(widget.txnRefId, widget.transactionType);
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _transaction = data;
              _loading = false;
            });
          }
          final status = (data['status'] ?? '').toString().toUpperCase();
          if (status == 'SUCCESS' || status == 'FAILED') {
            _isPolling = false;
            break;
          }
        } else {
          if (mounted) setState(() => _loading = false);
        }
      } catch (e) {
        debugPrint('AEPS status poll error: $e');
        if (mounted) setState(() => _loading = false);
      }
      _pollCount++;
      if (_isPolling) await Future.delayed(const Duration(seconds: 3));
    }
    // Max polls reached
    if (_isPolling && mounted) {
      setState(() => _isPolling = false);
    }
  }

  Future<void> _manualRefresh() async {
    setState(() {
      _loading = true;
      _isPolling = true;
      _pollCount = 0;
    });
    _startPolling();
  }

  String get _txnTypeLabel {
    switch (widget.transactionType) {
      case 'CASH_WITHDRAWAL': return 'Cash Withdrawal';
      case 'BALANCE_ENQUIRY': return 'Balance Enquiry';
      case 'MINI_STATEMENT':  return 'Mini Statement';
      default: return widget.transactionType;
    }
  }

  IconData get _txnTypeIcon {
    switch (widget.transactionType) {
      case 'CASH_WITHDRAWAL': return Icons.payments_outlined;
      case 'BALANCE_ENQUIRY': return Icons.account_balance_wallet_outlined;
      case 'MINI_STATEMENT':  return Icons.receipt_long_outlined;
      default: return Icons.fingerprint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_txnTypeLabel),
        backgroundColor: const Color(0xFF0D6B4F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _manualRefresh,
              tooltip: 'Refresh Status',
            ),
        ],
      ),
      body: _loading
          ? _buildLoadingState()
          : _transaction == null
              ? _buildErrorState()
              : _buildStatusBody(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF0D6B4F).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fingerprint, size: 60, color: Color(0xFF0D6B4F)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Verifying Transaction...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0D6B4F)),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we confirm your AEPS transaction',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Color(0xFFE0E0E0),
              color: Color(0xFF0D6B4F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red.shade400),
            ),
            const SizedBox(height: 24),
            const Text(
              'Unable to fetch status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _manualRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6B4F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBody() {
    final tx = _transaction!;
    final status = (tx['status'] ?? '').toString().toUpperCase();
    final isSuccess = status == 'SUCCESS';
    final isFailed  = status == 'FAILED';
    final isPending = !isSuccess && !isFailed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Status Banner ─────────────────────────────────────────
          _buildStatusBanner(isSuccess, isFailed, isPending, tx),
          const SizedBox(height: 20),

          // ── View Receipt Button (SUCCESS only) ────────────────────
          if (isSuccess) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AepsReceiptScreen(
                      txnRefId: widget.txnRefId,
                      transactionData: tx,
                    ),
                  ),
                ),
                icon: const Icon(Icons.receipt_long),
                label: const Text('VIEW & PRINT RECEIPT', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6B4F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Processing indicator ───────────────────────────────────
          if (isPending) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Transaction is being processed',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
                        Text('Auto-refreshing every 3 seconds',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _manualRefresh,
                icon: const Icon(Icons.refresh, color: Color(0xFF0D6B4F)),
                label: const Text('Check Status Now', style: TextStyle(color: Color(0xFF0D6B4F))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0D6B4F)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Transaction Details ────────────────────────────────────
          _buildDetailCard(
            title: 'Transaction Details',
            icon: Icons.receipt_outlined,
            rows: [
              _Row('Transaction Type', _txnTypeLabel),
              _Row('Reference ID', tx['txnRefId'] ?? tx['merchantRefId'] ?? 'N/A'),
              _Row('RRN', tx['rrn'] ?? 'N/A'),
              _Row('STAN', tx['stan'] ?? 'N/A'),
              if (widget.transactionType == 'CASH_WITHDRAWAL')
                _Row('Amount', '₹${tx['amount'] ?? widget.amount}'),
              _Row('Date & Time', _formatDate(tx['createdAt'] ?? tx['timestamp'])),
              _Row('Status', status),
            ],
          ),
          const SizedBox(height: 16),

          // ── Aadhaar / Customer Details ─────────────────────────────
          _buildDetailCard(
            title: 'Customer Details',
            icon: Icons.person_outline,
            rows: [
              _Row('Aadhaar (last 4)', tx['aadhaarLast4'] ?? tx['maskedAadhaar'] ?? 'XXXX'),
              _Row('Bank Name', tx['bankName'] ?? tx['bankIin'] ?? 'N/A'),
              _Row('Mobile', tx['mobileNumber'] ?? tx['mobile'] ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),

          // ── Mini Statement Entries (if applicable) ─────────────────
          if (widget.transactionType == 'MINI_STATEMENT' &&
              tx['miniStatementData'] != null)
            _buildMiniStatementCard(tx['miniStatementData']),

          // ── Balance (if balance enquiry) ───────────────────────────
          if (widget.transactionType == 'BALANCE_ENQUIRY' &&
              tx['balance'] != null)
            _buildBalanceCard(tx),

          const SizedBox(height: 16),

          // ── Agent / Merchant Details ───────────────────────────────
          _buildDetailCard(
            title: 'Agent Details',
            icon: Icons.store_outlined,
            rows: [
              _Row('Merchant ID', tx['merchantId'] ?? 'N/A'),
              _Row('Terminal ID', tx['terminalId'] ?? 'N/A'),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(bool isSuccess, bool isFailed, bool isPending, Map<String, dynamic> tx) {
    Color bgColor;
    Color iconColor;
    IconData statusIcon;
    String statusText;
    String statusSub;

    if (isSuccess) {
      bgColor    = const Color(0xFF0D6B4F);
      iconColor  = Colors.white;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Transaction Successful';
      statusSub  = widget.transactionType == 'CASH_WITHDRAWAL'
          ? '₹${tx['amount'] ?? widget.amount} Withdrawn'
          : widget.transactionType == 'BALANCE_ENQUIRY'
              ? 'Balance Retrieved'
              : 'Statement Retrieved';
    } else if (isFailed) {
      bgColor    = Colors.red.shade600;
      iconColor  = Colors.white;
      statusIcon = Icons.cancel_rounded;
      statusText = 'Transaction Failed';
      statusSub  = tx['errorMessage'] ?? tx['message'] ?? 'Please try again';
    } else {
      bgColor    = Colors.orange.shade600;
      iconColor  = Colors.white;
      statusIcon = Icons.hourglass_top_rounded;
      statusText = 'Processing...';
      statusSub  = 'Your transaction is being verified';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: bgColor.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Icon(statusIcon, size: 72, color: iconColor),
          const SizedBox(height: 12),
          Text(statusText,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Text(statusSub,
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85)),
            textAlign: TextAlign.center),
          const SizedBox(height: 16),
          // Reference ID chip
          GestureDetector(
            onTap: () {
              final ref = tx['txnRefId'] ?? tx['merchantRefId'] ?? '';
              Clipboard.setData(ClipboardData(text: ref));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reference ID copied'), duration: Duration(seconds: 1)),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, size: 14, color: Colors.white.withOpacity(0.9)),
                  const SizedBox(width: 6),
                  Text(
                    'Ref: ${tx['txnRefId'] ?? tx['merchantRefId'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required List<_Row> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FAF5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF0D6B4F), size: 20),
                const SizedBox(width: 10),
                Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D6B4F))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: rows.map((row) => _buildRow(row.label, row.value)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    final isStatus = label == 'Status';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: isStatus
                ? _buildStatusChip(value)
                : Text(value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'SUCCESS': color = const Color(0xFF0D6B4F); break;
      case 'FAILED':  color = Colors.red.shade600; break;
      default:        color = Colors.orange.shade600;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildBalanceCard(Map<String, dynamic> tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D6B4F), Color(0xFF1A9970)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0D6B4F).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Account Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('₹${tx['balance']}',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(tx['bankName'] ?? '',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMiniStatementCard(dynamic entries) {
    final List<dynamic> list = entries is List ? entries : [];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FAF5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.list_alt, color: Color(0xFF0D6B4F), size: 20),
                SizedBox(width: 10),
                Text('Mini Statement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D6B4F))),
              ],
            ),
          ),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No statement entries available', style: TextStyle(color: Colors.grey)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (_, i) {
                final entry = list[i] as Map<String, dynamic>;
                final isCredit = (entry['type'] ?? '').toString().toUpperCase() == 'CREDIT';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isCredit ? Colors.green.shade50 : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 18,
                          color: isCredit ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry['narration'] ?? 'Transaction',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(_formatDate(entry['date']),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      Text('₹${entry['amount'] ?? '0'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
                        )),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime.toString()).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return dateTime.toString();
    }
  }
}

class _Row {
  final String label;
  final String value;
  const _Row(this.label, this.value);
}