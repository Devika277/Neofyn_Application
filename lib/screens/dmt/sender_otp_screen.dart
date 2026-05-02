// screens/dmt/sender_otp_screen.dart
import 'package:flutter/material.dart';
import '../../services/DMT/dmt_service.dart';
import './sender_dashboard_screen.dart';

class SenderOtpScreen extends StatefulWidget {
  final String mobileNumber;
  final bool isExistingUser;
  final String senderId;  // Make required, not nullable
  final String senderName;  // Allow null
  final VoidCallback? onVerificationSuccess;

  const SenderOtpScreen({
    super.key,
    required this.mobileNumber,
    this.isExistingUser = false,
    required this.senderId,  // Now required
    required this.senderName,
    this.onVerificationSuccess,
  });

  @override
  State<SenderOtpScreen> createState() => _SenderOtpScreenState();
}

class _SenderOtpScreenState extends State<SenderOtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  late DMTService _dmtService;

  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 30;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _dmtService = DMTService('http://192.168.2.151:3000');
    _startResendTimer();
    
    // Debug logs
    print('SenderOtpScreen initialized with:');
    print('Mobile: ${widget.mobileNumber}');
    print('SenderId: ${widget.senderId}');
    print('SenderName: ${widget.senderName}');
  }
  
  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
  
  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
        _startResendTimer();
      }
    });
  }
  
  String get _otpCode {
    return _otpControllers.map((c) => c.text).join();
  }
  
  Future<void> _verifyOTP() async {
    if (_otpCode.length != 6) {
      setState(() => _error = 'Please enter 6-digit OTP');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final result = await _dmtService.verifyOTP(
        mobileNumber: widget.mobileNumber,
        otp: _otpCode,
      );
      
      print('Verify OTP result: $result');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['success'] == true) {
        // Call the success callback if provided
        if (widget.onVerificationSuccess != null) {
          widget.onVerificationSuccess!();
        } else {
          // Default navigation with null safety
          final senderId = widget.senderId ?? widget.mobileNumber;
          final senderName = widget.senderName ?? 'Sender';
          
          print('Navigating to dashboard with:');
          print('SenderId: $senderId');
          print('SenderName: $senderName');
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SenderDashboardScreen(
                mobileNumber: widget.mobileNumber,
                senderId: senderId,
                senderName: senderName, accountNumber: '', ifscCode: '', monthlyLimit: 0.0, monthlyUsed: 0.0,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _error = result['message'] ?? 'Invalid OTP. Please try again.';
        });
      }
      
    } catch (e) {
      print('Verify OTP error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _resendOTP() async {
    if (_resendTimer > 0) return;
    
    setState(() {
      _isResending = true;
      _error = null;
    });
    
    try {
      final result = await _dmtService.sendOTP(widget.mobileNumber);
      
      print('Resend OTP result: $result');
      
      if (!mounted) return;
      
      setState(() {
        _isResending = false;
        _resendTimer = 30;
      });
      
      if (result['success'] == true) {
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent successfully'),
            backgroundColor: Color(0xFF2ECC71),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to resend OTP';
        });
      }
      
    } catch (e) {
      print('Resend OTP error: $e');
      setState(() {
        _error = e.toString();
        _isResending = false;
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
          'Verify OTP',
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
                child: Column(
                  children: [
                    const Icon(
                      Icons.security,
                      color: Color(0xFF2ECC71),
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Verification Code',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We have sent a 6-digit OTP to +91 ${widget.mobileNumber}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              const Text(
                'Enter OTP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 50,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Color(0xFF2ECC71)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1A1A1A),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        
                        if (_otpCode.length == 6) {
                          _verifyOTP();
                        }
                      },
                    ),
                  ),
                ),
              ),
              
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _verifyOTP,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Verify & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive OTP? ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  if (_resendTimer > 0)
                    Text(
                      'Resend in 0:${_resendTimer.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.grey),
                    )
                  else
                    TextButton(
                      onPressed: _isResending ? null : _resendOTP,
                      child: _isResending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2ECC71),
                              ),
                            )
                          : const Text(
                              'Resend OTP',
                              style: TextStyle(color: Color(0xFF2ECC71)),
                            ),
                    ),
                ],
              ),
              
              const Spacer(),
              
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    _showHelpDialog();
                  },
                  icon: const Icon(Icons.help_outline, color: Colors.grey, size: 16),
                  label: const Text(
                    'Did not receive OTP?',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
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
        title: const Text(
          'OTP Not Received?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Try these solutions:',
              style: TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '• Check your mobile network\n'
              '• Wait for 30 seconds\n'
              '• Check if SMS is blocked\n'
              '• Restart your phone\n'
              '• Contact customer support',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF2ECC71))),
          ),
        ],
      ),
    );
  }
}