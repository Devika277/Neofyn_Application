// lib/screens/payout/payout_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payout_provider.dart';
import '../../models/payout_request.dart';
import '../payout/payout_status_screen.dart';
import '../payout/payout_receipt_screen.dart';


class PayoutFormScreen extends StatefulWidget {
  const PayoutFormScreen({Key? key}) : super(key: key);
  
  @override
  State<PayoutFormScreen> createState() => _PayoutFormScreenState();
}

class _PayoutFormScreenState extends State<PayoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _mobileController = TextEditingController();
  final _beneficiaryNameController = TextEditingController();
  
  bool _isSubmitting = false;
  
  // ✅ REMOVED initState that called loadMasterData()
  // Master data is now loaded once by PayoutHomeScreen
  @override
  void initState() {
    super.initState();
    // Do NOT call loadMasterData() here - it's already loaded by parent screen
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _mobileController.dispose();
    _beneficiaryNameController.dispose();
    super.dispose();
  }
  
  Future<void> _submitPayout() async {
    if (!_formKey.currentState!.validate()) return;
    
    final provider = Provider.of<PayoutProvider>(context, listen: false);
    
    // Validate that dropdowns are selected
    if (provider.selectedBankCode == null) {
      _showErrorDialog('Please select a beneficiary bank');
      return;
    }
    if (provider.selectedPurposeCode == null) {
      _showErrorDialog('Please select a payment purpose');
      return;
    }
    if (provider.selectedStateCode == null) {
      _showErrorDialog('Please select a beneficiary location (state)');
      return;
    }
        // Inside _submitPayout validation
    if (double.parse(_amountController.text) < 100) {
        _showErrorDialog('Minimum payout amount is ₹100');
        return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      final payoutRequest = PayoutRequest(
        amount: double.parse(_amountController.text),
        merchantRefId: 'MER${DateTime.now().millisecondsSinceEpoch}',
        beneficiaryBank: provider.selectedBankCode!,
        paymentPurpose: provider.selectedPurposeCode!,
        paymentMode: provider.selectedPaymentMode ?? 'imps',
        beneficiaryAccountNumber: _accountNumberController.text,
        beneficiaryIFSC: _ifscController.text.toUpperCase(),
        beneficiaryMobileNumber: _mobileController.text,
        beneficiaryName: _beneficiaryNameController.text,
        beneficiaryLocation: provider.selectedStateCode!,
      );
      
   final response = await provider.initiatePayout(payoutRequest.toJson());
    
    if (mounted) {
      // Backend returns { success: true, data: { merchantRefId, status: 'QUEUED' } }
      if (response['success'] == true) {
        final data = response['data'];
        final merchantRefId = data['merchantRefId'] ?? '';
        _showQueuedDialog(merchantRefId);
        _clearForm();
      } else {
        _showErrorDialog(response['message'] ?? 'Payout failed');
      }
    }
  } catch (e) {
    if (mounted) {
      _showErrorDialog(e.toString());
    }
  } finally {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}
  
  void _clearForm() {
    _amountController.clear();
    _accountNumberController.clear();
    _ifscController.clear();
    _mobileController.clear();
    _beneficiaryNameController.clear();
    Provider.of<PayoutProvider>(context, listen: false).clearSelections();
  }
  
 void _showQueuedDialog(String merchantRefId) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.hourglass_empty, color: Colors.orange),
          SizedBox(width: 8),
          Text('Payout Queued'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your payout request has been submitted and is being processed.'),
          const SizedBox(height: 12),
          Text('Reference ID: $merchantRefId', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('You can check the final status later in Transaction History.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Optional: navigate to status screen
            Navigator.push(context, MaterialPageRoute(builder: (_) => PayoutStatusScreen(merchantRefId: merchantRefId)));
          },
          child: const Text('OK'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Navigate to status screen (create this screen as described earlier)
            Navigator.push(context, MaterialPageRoute(builder: (_) => PayoutReceiptScreen(merchantRefId: merchantRefId)));
          },
          child: const Text('Check Status'),
        ),
      ],
    ),
  );

    
    // showDialog(
    //   context: context,
    //   builder: (_) => AlertDialog(
    //     title: const Row(
    //       children: [
    //         Icon(Icons.check_circle, color: Colors.green),
    //         SizedBox(width: 8),
    //         Text('Success'),
    //       ],
    //     ),
    //     content: Column(
    //       mainAxisSize: MainAxisSize.min,
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Text('Transaction ID: $txnId'),
    //         const SizedBox(height: 8),
    //         Text('Status: $txnStatus'),
    //         const SizedBox(height: 8),
    //         Text('Amount: ₹$amount'),
    //         if (merchantRefId.isNotEmpty) ...[
    //           const SizedBox(height: 8),
    //           Text('Reference: $merchantRefId'),
    //         ],
    //       ],
    //     ),
    //     actions: [
    //       TextButton(
    //         onPressed: () => Navigator.pop(context),
    //         child: const Text('OK'),
    //       ),
    //     ],
    //   ),
    // );
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<PayoutProvider>(
      builder: (context, provider, child) {
        // Show loader if master data is still loading AND no data yet
        if (provider.isLoading && provider.banks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Show error if any
        if (provider.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(provider.errorMessage),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadMasterData(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        // Form UI
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter amount';
                  if (double.tryParse(value) == null) return 'Invalid amount';
                  if (double.parse(value) <= 0) return 'Amount must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Beneficiary Name
              TextFormField(
                controller: _beneficiaryNameController,
                decoration: const InputDecoration(
                  labelText: 'Beneficiary Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter beneficiary name' : null,
              ),
              const SizedBox(height: 16),
              
              // Account Number
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  prefixIcon: Icon(Icons.account_balance),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter account number';
                  if (value.length < 9 || value.length > 18) return 'Account number must be 9-18 digits';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // IFSC Code
              TextFormField(
                controller: _ifscController,
                decoration: const InputDecoration(
                  labelText: 'IFSC Code',
                  prefixIcon: Icon(Icons.code),
                  border: OutlineInputBorder(),
                  hintText: 'Example: HDFC0000516',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter IFSC code';
                  final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
                  if (!ifscRegex.hasMatch(value.toUpperCase())) {
                    return 'Invalid IFSC code format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Mobile Number
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter mobile number';
                  if (value.length != 10) return 'Enter 10 digits';
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) return 'Invalid mobile number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Bank Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Beneficiary Bank',
                  prefixIcon: Icon(Icons.account_balance),
                  border: OutlineInputBorder(),
                ),
                value: provider.selectedBankCode,
                items: provider.banks.map((bank) {
                  return DropdownMenuItem(
                    value: bank.code,
                    child: Text(bank.description),
                  );
                }).toList(),
                onChanged: (value) => provider.setSelectedBank(value!),
                validator: (value) => value == null ? 'Select bank' : null,
              ),
              const SizedBox(height: 16),
              
              // Purpose Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Payment Purpose',
                  prefixIcon: Icon(Icons.receipt),
                  border: OutlineInputBorder(),
                ),
                value: provider.selectedPurposeCode,
                items: provider.purposes.map((purpose) {
                  return DropdownMenuItem(
                    value: purpose.code,
                    child: Text(purpose.description),
                  );
                }).toList(),
                onChanged: (value) => provider.setSelectedPurpose(value!),
                validator: (value) => value == null ? 'Select purpose' : null,
              ),
              const SizedBox(height: 16),
              
              // State Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Beneficiary Location (State)',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
                value: provider.selectedStateCode,
                items: provider.states.map((state) {
                  return DropdownMenuItem(
                    value: state.code,
                    child: Text(state.description),
                  );
                }).toList(),
                onChanged: (value) => provider.setSelectedState(value!),
                validator: (value) => value == null ? 'Select state' : null,
              ),
              const SizedBox(height: 16),
              
              // Payment Mode
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  prefixIcon: Icon(Icons.speed),
                  border: OutlineInputBorder(),
                ),
                value: provider.selectedPaymentMode ?? 'IMPS',
                items: const [
                  DropdownMenuItem(value: 'IMPS', child: Text('IMPS (Instant)')),
                  DropdownMenuItem(value: 'NEFT', child: Text('NEFT (1-2 hours)')),
                ],
                onChanged: (value) => provider.setSelectedPaymentMode(value!),
              ),
              const SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting || provider.isLoading ? null : _submitPayout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send Payout', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }
}