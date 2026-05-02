// screens/dmt/sender_lookup_screen.dart
import 'package:flutter/material.dart';
import '../../services/DMT/dmt_service.dart';
import '../../services/storage_service.dart';
import 'package:my_app/screens/dmt/sender_registration_form.dart';
import 'package:my_app/screens/dmt/sender_dashboard_screen.dart';

class SenderLookupScreen extends StatefulWidget {
  const SenderLookupScreen({super.key});

  @override
  State<SenderLookupScreen> createState() => _SenderLookupScreenState();
}

class _SenderLookupScreenState extends State<SenderLookupScreen> {
  final TextEditingController _mobileController = TextEditingController();
  late DMTService _dmtService;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dmtService = DMTService('http://192.168.2.151:3000');
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _lookupSender() async {
    final mobile = _mobileController.text.trim();
    
    print('========== LOOKUP SENDER START ==========');
    print('Mobile number entered: $mobile');

    if (mobile.isEmpty) {
      setState(() => _error = 'Please enter mobile number');
      return;
    }
    
    if (mobile.length != 10) {
      setState(() => _error = 'Please enter valid 10-digit mobile number');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      print('Calling checkSender API for mobile: $mobile');
      final result = await _dmtService.checkSender(mobile);
      print('checkSender result: $result');

      if (!mounted) return;
      
      if (result['exists'] == true) {
        print('Sender exists - Going directly to dashboard (NO OTP)');
        
        // Existing sender - Go directly to dashboard
        final senderId = result['senderId'] ?? mobile;
        final senderName = result['senderName'] ?? 'Sender';
        final accountNumber = result['accountNumber'] ?? 'Not added';
        final ifscCode = result['ifscCode'] ?? 'Not added';
        final monthlyLimit = result['monthlyLimit'] ?? 25000;
        final monthlyUsed = result['monthlyUsed'] ?? 0;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SenderDashboardScreen(
              mobileNumber: mobile,
              senderId: senderId,
              senderName: senderName,
              accountNumber: accountNumber,
              ifscCode: ifscCode,
              monthlyLimit: monthlyLimit.toDouble(),
              monthlyUsed: monthlyUsed.toDouble(),
            ),
          ),
        );
      } else {
        print('New sender - Navigating to registration form');
        
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SenderRegistrationForm(
              mobileNumber: mobile,
            ),
          ),
        );
      }
      
    } catch (e) {
      print('Error in _lookupSender: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2ECC71)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sender Lookup',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.info_outline, color: Color(0xFF2ECC71), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Enter the mobile number to view sender dashboard.\nIf not registered, you can register them.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text('Sender Mobile Number', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _mobileController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: '9876543210',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.phone_android, color: Colors.grey),
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[700]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[700]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2ECC71))),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _lookupSender,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const Spacer(),
              Center(
                child: TextButton.icon(
                  onPressed: () => _showHelpDialog(),
                  icon: const Icon(Icons.help_outline, color: Colors.grey, size: 16),
                  label: const Text('Need help?', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Sender Registration', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('What is a Sender?', style: TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text('A sender is the person who wants to send money through DMT.', style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: Color(0xFF2ECC71)))),
        ],
      ),
    );
  }
}