// screens/dmt/add_beneficiary_screen.dart
import 'package:flutter/material.dart';
import '../../services/DMT/dmt_service.dart';

class AddBeneficiaryScreen extends StatefulWidget {
  final String senderMobile;
  final VoidCallback onBeneficiaryAdded;

  const AddBeneficiaryScreen({
    super.key,
    required this.senderMobile,
    required this.onBeneficiaryAdded,
  });

  @override
  State<AddBeneficiaryScreen> createState() => _AddBeneficiaryScreenState();
}

class _AddBeneficiaryScreenState extends State<AddBeneficiaryScreen> {
  final _formKey = GlobalKey<FormState>();
  late DMTService _dmtService;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController(text: 'New Delhi');
  final TextEditingController _stateController = TextEditingController(text: 'DL');
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dmtService = DMTService('http://192.168.2.151:3000');
  }

  Future<void> _addBeneficiary() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _dmtService.registerBeneficiary({
        'senderMobile': widget.senderMobile,
        'name': _nameController.text.trim(),
        'accountNumber': _accountController.text.trim(),
        'ifsc': _ifscController.text.trim().toUpperCase(),
        'bankName': _bankNameController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
      });

      if (!mounted) return;

      if (result['success'] == true) {
        widget.onBeneficiaryAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beneficiary added successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to add beneficiary')),
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
        title: const Text('Add Beneficiary', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(_nameController, 'Beneficiary Name', Icons.person, validator: true),
                    const SizedBox(height: 16),
                    _buildTextField(_accountController, 'Account Number', Icons.account_balance, 
                        keyboardType: TextInputType.number, validator: true),
                    const SizedBox(height: 16),
                    _buildTextField(_ifscController, 'IFSC Code', Icons.code, 
                        toUpperCase: true, validator: true),
                    const SizedBox(height: 16),
                    _buildTextField(_bankNameController, 'Bank Name', Icons.account_balance, validator: true),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(_cityController, 'City', Icons.location_city, validator: true),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(_stateController, 'State', Icons.location_city, validator: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _addBeneficiary,
                        child: const Text('Add Beneficiary', 
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool toUpperCase = false,
    bool validator = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      onChanged: toUpperCase
          ? (value) => controller.value = controller.value.copyWith(text: value.toUpperCase())
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF2ECC71)),
        ),
      ),
      validator: validator ? (value) => value?.isEmpty == true ? 'Enter $label' : null : null,
    );
  }
}