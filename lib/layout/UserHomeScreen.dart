import 'package:flutter/material.dart';
import 'package:my_app/services/Recharges/rechargeFragment.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Ensure this path matches your project structure
import 'package:my_app/screens/login_screen.dart'; 
import '../screens/dmt/dmt_home_screen.dart';
import '../screens/aeps/aeps_screen.dart';
import '../services/AEPS/api_service.dart';



class UserHomeScreen extends StatefulWidget {
  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;
  String _name = "Devika M S";
  String _phone = "+91 98765 43210";
  late List<Widget> _pages; // Declare here

  @override
  void initState() {
    super.initState();
    _loadSession();
    
    // Initialize pages here so 'onLogout' can point to 'this._logout'
    _pages = [
      HomeDashboardContent(onLogout: _logout), 
      ServicesGridContent(),
      Center(child: Text("Profile Page", style: TextStyle(color: Colors.white))),
      Center(child: Text("Support Page", style: TextStyle(color: Colors.white))),
    ];
  }

  _loadSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name') ?? "Devika M S";
      _phone = prefs.getString('phone') ?? "+91 98765 43210";
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
  await ApiService.clearUser();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF1A1A1A),
        selectedItemColor: Color(0xFF2ECC71),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Services"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.headset_mic), label: "Contact"),
        ],
      ),
    );
  }
}



// --- PART 1: HOME HEADER ---
class HomeDashboardContent extends StatelessWidget { 
  final VoidCallback onLogout;

  const HomeDashboardContent({super.key, required this.onLogout});
  


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30), 
                bottomRight: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Added this
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 25, backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.green)),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Welcome back,", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text("Devika M S", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  // Logout Icon Button
                  IconButton(
                    icon: const Icon(Icons.logout, color: Color(0xFF2ECC71)),
                    onPressed: () => _showLogoutDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text("Total Balance", style: TextStyle(color: Colors.grey)),
              Text("₹ 88,000", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionBtn(Icons.add, "Top Up", onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RechargeCategoryScreen()),
                      );
                    }
                  ),

                  _actionBtn(Icons.send, "Send"),
                  _actionBtn(Icons.swap_horiz, "Move"),
                  _actionBtn(Icons.history, "History"),
                ],
              )
            ],
          ),
        ),
        Expanded(child: ServicesGridContent()),
      ],
    );
  }

  // Moved Dialog inside the class to make it easier to manage
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (innerContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to sign out?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(innerContext),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(innerContext); // Close dialog
              onLogout(); // This calls the _logout function from the State
            },
            child: const Text("Logout", style: TextStyle(color: Color(0xFF2ECC71))),
          ),
        ],
      ),
    );
  }

 Widget _actionBtn(IconData icon, String label, {VoidCallback? onTap}) {
  return InkWell(
    onTap: onTap, // Now the widget actually listens for clicks
    child: Column(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFF2ECC71), 
          child: Icon(icon, color: Colors.black),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ),
  );
}
}

// --- PART 2: SERVICES GRID ---
class ServicesGridContent extends StatelessWidget {
  final List<Map<String, dynamic>> services = [
    {"name": "AEPS", "icon": Icons.fingerprint},
    {"name": "DMT", "icon": Icons.send_to_mobile},
    {"name": "Payout", "icon": Icons.account_balance},
    {"name": "MicroATM", "icon": Icons.atm},
    {"name": "CC Pay", "icon": Icons.credit_card},
    {"name": "Mobile", "icon": Icons.phone_android},
    {"name": "DTH", "icon": Icons.tv},
    {"name": "Electricity", "icon": Icons.lightbulb},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(15),
      child: GridView.builder(
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, 
          mainAxisSpacing: 10, 
          crossAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              final name = services[index]['name'];
              if (name == 'DMT') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DmtHomeScreen()),
                );
              } else if (name == 'Mobile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RechargeCategoryScreen()),
                );
              }   else if (name == 'AEPS') {
        // ✅ AEPS — First check if merchant is registered
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AepsScreen(merchantId: '',)),
        );
      }   else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$name service coming soon!")),
                );
              };
            },
            child: Card(
              color: Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(services[index]['icon'], color: Color(0xFF2ECC71), size: 30),
                  SizedBox(height: 8),
                  Text(services[index]['name'], 
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}