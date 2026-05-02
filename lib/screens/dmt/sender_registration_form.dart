// screens/dmt/sender_registration_form.dart
import 'package:flutter/material.dart';
import '../../services/DMT/dmt_service.dart';
import 'package:my_app/screens/dmt/sender_dashboard_screen.dart';

class SenderRegistrationForm extends StatefulWidget {
  final String mobileNumber;
  
  const SenderRegistrationForm({super.key, required this.mobileNumber});

  @override
  State<SenderRegistrationForm> createState() => _SenderRegistrationFormState();
}

class _SenderRegistrationFormState extends State<SenderRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  late DMTService _dmtService;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dmtService = DMTService('http://192.168.2.151:3000');
  }

  Future<void> _registerSender() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _dmtService.registerSender({
        'mobileNumber': widget.mobileNumber,
        'fullName': _nameController.text.trim(),
        'aadhaarNumber': _aadhaarController.text.trim(),
        'pincode': _pincodeController.text.trim(),
      });

      if (!mounted) return;

      if (result['success'] == true) {
        // Go directly to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SenderDashboardScreen(
              mobileNumber: widget.mobileNumber,
              senderId: result['senderId'] ?? widget.mobileNumber,
              senderName: _nameController.text.trim(),
              accountNumber: result['accountNumber'] ?? 'Not added',
              ifscCode: result['ifscCode'] ?? 'Not added',
              monthlyLimit: result['monthlyLimit'] ?? 25000,
              monthlyUsed: 0,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Registration failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
        title: const Text('Register Sender', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, color: Color(0xFF2ECC71)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mobile Number', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text('+91 ${widget.mobileNumber}', style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(_nameController, 'Full Name', Icons.person),
                    const SizedBox(height: 16),
                    _buildTextField(_aadhaarController, 'Aadhaar Number', Icons.credit_card, keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField(_pincodeController, 'Pincode', Icons.location_city, keyboardType: TextInputType.number),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _registerSender,
                        child: const Text('Register & Continue', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder:  OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF2ECC71)),
        ),
      ),
      validator: (value) => value?.isEmpty == true ? 'Enter $label' : null,
    );
  }
}