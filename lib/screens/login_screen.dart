import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/screens/register_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/UserHomeScreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> loginUser() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showToast("Please fill all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('https://kinsman-borax-colony.ngrok-free.dev/api/auth/login');
      
      print('Attempting login for phone: $phone');
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": phone,
          "password": password,
        }),
      ).timeout(const Duration(seconds: 15));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          
          await prefs.setString('accessToken', data['accessToken'] ?? "");
          await prefs.setString('userId', data['user']?['id']?.toString() ?? "");
          await prefs.setString('role', data['user']?['role'] ?? "");
          await prefs.setString('name', data['user']?['name'] ?? "");
          await prefs.setString('phone', data['user']?['phone'] ?? "");
          
          _showToast("Login Successful!");
          
          if (mounted) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => UserHomeScreen())
            );
          }
        } else {
          _showToast(data['message'] ?? "Login Failed");
        }
      } else if (response.statusCode == 401) {
        _showToast("Invalid phone number or password");
      } else {
        _showToast("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print('Error: $e');
      _showToast("Network Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: Duration(seconds: 3))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Center(
              child: Card(
                elevation: 8,
                shape: CircleBorder(),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.account_balance_wallet, size: 45, color: Colors.green),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text("Welcome Back", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            Text("Sign in to continue to your dashboard", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 40),
            Card(
              color: Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _phoneController,
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        labelStyle: TextStyle(color: Color(0xFF4CAF50)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF4CAF50))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(color: Color(0xFF4CAF50)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF4CAF50))),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text("Forgot Password?", style: TextStyle(color: Color(0xFF4CAF50))),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4CAF50),
                          shape: StadiumBorder(),
                        ),
                        onPressed: _isLoading ? null : loginUser,
                        child: _isLoading 
                          ? CircularProgressIndicator(color: Colors.black) 
                          : Text("Sign In", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[800])),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("New User?", style: TextStyle(color: Colors.grey))),
                        Expanded(child: Divider(color: Colors.grey[800])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Color(0xFF4CAF50), width: 2),
                          shape: StadiumBorder(),
                        ),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
                        },
                        child: Text("Create New Account", style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text("Secure login with SSL encryption", style: TextStyle(color: Colors.grey[700], fontSize: 11)),
          ],
        ),
      ),
    );
  }
}