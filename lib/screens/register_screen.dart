import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 1; // Tracks Step 1, 2, or 3
  bool _isLoading = false;
  bool _agreedToTerms = false;

  // STEP 1 Controllers
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  // STEP 2 Controllers
  final _busName = TextEditingController();
  final _busType = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pinCode = TextEditingController();
  final _busAddress = TextEditingController();

  // STEP 3 Controllers
  final _aadhaar = TextEditingController();
  final _pan = TextEditingController();

  // --- BACKEND LOGIC ---
  Future<void> submitRegistration() async {
    if (!_agreedToTerms) {
      _showToast("Please accept Terms and Conditions");
      return;
    }
    if (_aadhaar.text.length != 12) {
      _showToast("Aadhaar must be 12 digits");
      return;
    }

 setState(() => _isLoading = true);

  try {
    // Port 5000 as per your server.js
    final url = Uri.parse('http://192.168.2.151:3000/api/auth/register'); 
    
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "first_name": _firstName.text.trim(),     // Matched to first_name
        "last_name": _lastName.text.trim(),       // Matched to last_name
        "email": _email.text.trim(),
        "phone": _phone.text.trim(),
        "password": _password.text.trim(),
        "business_name": _busName.text.trim(),    // Matched to business_name
        "business_type": _busType.text.trim(),    // Matched to business_type
        "business_address": _busAddress.text.trim(), // Matched to business_address
        "city": _city.text.trim(),
        "state": _state.text.trim(),
        "pin_code": _pinCode.text.trim(),         // Matched to pin_code
        "aadhaar_number": _aadhaar.text.trim(),   // Matched to aadhaar_number
        "pan_number": _pan.text.trim(),           // Matched to pan_number
      }),
    );

    if (response.statusCode == 201) {
      _showToast("Registered successfully! Awaiting approval.");
      Navigator.pop(context);
    } else {
      final errorData = jsonDecode(response.body);
      _showToast(errorData['message'] ?? "Registration failed");
    }
  } catch (e) {
    _showToast("Network Error: $e");
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 50),
            _buildHeader(),
            const SizedBox(height: 20),
            
            // Progress Indicator (Equivalent to LinearProgressIndicator)
            LinearProgressIndicator(
              value: _currentStep / 3,
              backgroundColor: Color(0xFF333333),
              color: Color(0xFF4CAF50),
              minHeight: 6,
            ),
            const SizedBox(height: 24),

            // Conditional Step Rendering
            if (_currentStep == 1) _buildStep1(),
            if (_currentStep == 2) _buildStep2(),
            if (_currentStep == 3) _buildStep3(),
          ],
        ),
      ),
    );
  }

  // --- HEADER SECTION ---
  Widget _buildHeader() {
    return Column(
      children: [
        Card(
          elevation: 8,
          shape: CircleBorder(),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.person_add, color: Colors.green, size: 40),
          ),
        ),
        const SizedBox(height: 16),
        Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        Text("Join us and start your journey", style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  // --- STEP 1: PERSONAL ---
  Widget _buildStep1() {
    return Column(
      children: [
        _buildCardWrapper("Personal Information", [
          _buildTextField(_firstName, "First Name"),
          _buildTextField(_lastName, "Last Name"),
          _buildTextField(_email, "Email Address", inputType: TextInputType.emailAddress),
          _buildTextField(_phone, "Mobile Number", inputType: TextInputType.phone, limit: 10),
          _buildTextField(_password, "Password", isObscure: true),
        ]),
        const SizedBox(height: 24),
        _buildNextButton(() => setState(() => _currentStep = 2)),
      ],
    );
  }

  // --- STEP 2: BUSINESS ---
  Widget _buildStep2() {
    return Column(
      children: [
        _buildCardWrapper("Business Details", [
          _buildTextField(_busName, "Business Name"),
          _buildTextField(_busType, "Business Type"),
          _buildTextField(_city, "City"),
          _buildTextField(_state, "State"),
          _buildTextField(_pinCode, "PIN Code", inputType: TextInputType.number, limit: 6),
          _buildTextField(_busAddress, "Business Address", lines: 2),
        ]),
        const SizedBox(height: 16),
        _buildNavigationButtons(onBack: () => setState(() => _currentStep = 1), onNext: () => setState(() => _currentStep = 3)),
      ],
    );
  }

  // --- STEP 3: IDENTITY ---
  Widget _buildStep3() {
    return Column(
      children: [
        _buildCardWrapper("Identity Verification", [
          _buildTextField(_aadhaar, "Aadhaar Number", inputType: TextInputType.number, limit: 12),
          _buildTextField(_pan, "PAN Number", limit: 10),
          const SizedBox(height: 10),
          CheckboxListTile(
            title: Text("I agree to the Terms and Conditions", style: TextStyle(color: Colors.grey, fontSize: 14)),
            value: _agreedToTerms,
            activeColor: Color(0xFF4CAF50),
            onChanged: (val) => setState(() => _agreedToTerms = val!),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ]),
        const SizedBox(height: 16),
        _buildNavigationButtons(
          onBack: () => setState(() => _currentStep = 2), 
          onNext: _isLoading ? null : submitRegistration,
          nextLabel: "Register →"
        ),
      ],
    );
  }

  // --- REUSABLE UI COMPONENTS ---

  Widget _buildCardWrapper(String title, List<Widget> children) {
    return Card(
      color: Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Color(0xFF4CAF50), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isObscure = false, TextInputType inputType = TextInputType.text, int? limit, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: inputType,
        maxLength: limit,
        maxLines: lines,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: hint,
          counterText: "",
          labelStyle: TextStyle(color: Colors.grey),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF4CAF50))),
        ),
      ),
    );
  }

  Widget _buildNextButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4CAF50), shape: StadiumBorder()),
        child: Text("Continue →", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildNavigationButtons({required VoidCallback onBack, required VoidCallback? onNext, String nextLabel = "Continue →"}) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(side: BorderSide(color: Color(0xFF4CAF50)), shape: StadiumBorder(), padding: EdgeInsets.symmetric(vertical: 16)),
            child: Text("← Back", style: TextStyle(color: Color(0xFF4CAF50))),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4CAF50), shape: StadiumBorder(), padding: EdgeInsets.symmetric(vertical: 16)),
            child: _isLoading ? CircularProgressIndicator(color: Colors.black) : Text(nextLabel, style: TextStyle(color: Colors.black)),
          ),
        ),
      ],
    );
  }
}