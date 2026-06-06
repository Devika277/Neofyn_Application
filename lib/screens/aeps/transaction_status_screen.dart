import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/aeps_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';

class TransactionStatusScreen extends StatefulWidget {
  const TransactionStatusScreen({super.key});

  @override
  State<TransactionStatusScreen> createState() => _TransactionStatusScreenState();
}

class _TransactionStatusScreenState extends State<TransactionStatusScreen> {
  final TextEditingController _transactionIdController = TextEditingController();
  final TextEditingController _merchantRefIdController = TextEditingController();
  
  Map<String, dynamic>? _transactionDetails;
  bool _isSearching = false;
  String? _errorMessage;

  Future<void> _checkStatus() async {
    final transactionId = _transactionIdController.text.trim();
    final merchantRefId = _merchantRefIdController.text.trim();
    
    if (transactionId.isEmpty && merchantRefId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter either Transaction ID or Merchant Reference ID';
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });
    
    try {
      final provider = Provider.of<AepsProvider>(context, listen: false);
      final response = await provider.getTransactionStatus(
        provider.merchantId!,
        merchantRefId.isNotEmpty ? merchantRefId : transactionId,
      );
      
      setState(() {
        _transactionDetails = response;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _transactionDetails = null;
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case '000':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case '000':
        return 'Success';
      case 'PENDING':
        return 'Pending';
      case 'FAILED':
        return 'Failed';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Status'),
        backgroundColor: const Color(0xFF6200EE),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _transactionIdController,
                      decoration: InputDecoration(
                        labelText: 'Transaction ID',
                        hintText: 'Enter transaction ID',
                        prefixIcon: const Icon(Icons.receipt),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'OR',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _merchantRefIdController,
                      decoration: InputDecoration(
                        labelText: 'Merchant Reference ID',
                        hintText: 'Enter merchant reference ID',
                        prefixIcon: const Icon(Icons.store),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Check Status',
                      onPressed: _checkStatus,
                      isLoading: _isSearching,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Transaction Details
            if (_transactionDetails != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Transaction Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Status',
                        _getStatusText(_transactionDetails!['status'] ?? ''),
                        _getStatusColor(_transactionDetails!['status'] ?? ''),
                      ),
                      _buildDivider(),
                      _buildDetailRow(
                        'Status Description',
                        _transactionDetails!['statusDescription'] ?? 'N/A',
                        Colors.grey,
                      ),
                      _buildDivider(),
                      _buildDetailRow(
                        'Transaction ID',
                        _transactionDetails!['txnRefId'] ?? 'N/A',
                        Colors.grey,
                      ),
                      _buildDivider(),
                      _buildDetailRow(
                        'RRN',
                        _transactionDetails!['rrn'] ?? 'N/A',
                        Colors.grey,
                      ),
                      _buildDivider(),
                      _buildDetailRow(
                        'Amount',
                        _transactionDetails!['transactionAmount'] != null
                            ? '₹${_transactionDetails!['transactionAmount']}'
                            : 'N/A',
                        Colors.grey,
                      ),
                      _buildDivider(),
                      _buildDetailRow(
                        'Bank IIN',
                        _transactionDetails!['bankIIN'] ?? 'N/A',
                        Colors.grey,
                      ),
                      _buildDivider(),
                      _buildDetailRow(
                        'NPCI Message',
                        _transactionDetails!['npciMessage'] ?? 'N/A',
                        Colors.grey,
                      ),
                      _buildDivider(),
                      _buildDetailRow(
                        'Date & Time',
                        _transactionDetails!['txnDateTime'] ?? 'N/A',
                        Colors.grey,
                      ),
                      if (_transactionDetails!['availableBalance'] != null) ...[
                        _buildDivider(),
                        _buildDetailRow(
                          'Available Balance',
                          '₹${_transactionDetails!['availableBalance']}',
                          Colors.green,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDivider() {
    return Divider(color: Colors.grey[200], height: 1);
  }
}