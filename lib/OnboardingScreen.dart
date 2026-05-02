import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';



class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // This controls the sliding pages
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 1. YOUR DATA (Titles, Descriptions, and Icons)
  final List<Map<String, dynamic>> _pages = [
    {
      "title": "Easiest Money Transfer",
      "desc": "Send money to any bank account instantly.",
      "icon": Icons.send_rounded,
    },
    {
      "title": "Cashless Withdrawals",
      "desc": "Withdraw cash without an ATM using partner points.",
      "icon": Icons.payments_outlined,
    },
    {
      "title": "Fingerprint Recharges",
      "desc": "Pay bills and recharge with just a touch.",
      "icon": Icons.fingerprint_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme like your XML
      body: Stack(
        children: [
          // 2. THE SLIDER (ViewPager2 equivalent)
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPageContent(
                title: _pages[index]['title'],
                desc: _pages[index]['desc'],
                icon: _pages[index]['icon'],
              );
            },
          ),

          // 3. THE BOTTOM SECTION (Buttons and Dots)
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The Indicator Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) => _buildDot(index)),
                ),
                const SizedBox(height: 30),

                // The Buttons Container (Matte Black area)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A), // Matte Black
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Login Button (Emerald Green)
                      _buildButton(
                        "Log in",
                         const Color(0xFF2ECC71), 
                         Colors.black,
                         onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },),
                      
                      const SizedBox(height: 15),
                      // Signup Button (Outlined)
                     
                      _buildOutlineButton(
                        "Sign up",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegisterScreen()), // Replace with your Register class name
                          );
                        },),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS (To keep code clean) ---

  Widget _buildPageContent({required String title, required String desc, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Icon(icon, size: 150, color: const Color(0xFF2ECC71)),
          ),
          const SizedBox(height: 50),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 100), // Leave space for buttons
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      height: 8,
      width: _currentPage == index ? 24 : 8,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFF2ECC71) : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildButton(String text, Color bgColor, Color textColor, {required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: bgColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: onTap,
        child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildOutlineButton(String text,{required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}