import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class RechargeDetailsScreen extends StatefulWidget {
  final String mobile;
  RechargeDetailsScreen({required this.mobile});

  @override
  _RechargeDetailsScreenState createState() => _RechargeDetailsScreenState();
}

class _RechargeDetailsScreenState extends State<RechargeDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> _operators = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  
  String? selectedOperatorCode;
  String? selectedOperatorName;
  String selectedCircle = "DLT";
  
  // Fixed plans - no API call to prevent overflow
  final List<Map<String, dynamic>> _plans = [
    {
      'amount': 199,
      'validity': '28 Days',
      'data': '1.5GB/Day',
      'voice': 'Unlimited',
      'description': 'Popular Plan',
      'category': 'combo',
    },
    {
      'amount': 299,
      'validity': '28 Days',
      'data': '2GB/Day',
      'voice': 'Unlimited',
      'description': 'Value Plan',
      'category': 'combo',
    },
    {
      'amount': 399,
      'validity': '56 Days',
      'data': '2GB/Day',
      'voice': 'Unlimited',
      'description': 'Long Validity',
      'category': 'combo',
    },
    {
      'amount': 599,
      'validity': '84 Days',
      'data': '3GB/Day',
      'voice': 'Unlimited',
      'description': 'Premium Plan',
      'category': 'combo',
    },
    {
      'amount': 49,
      'validity': '1 Day',
      'data': '1GB',
      'voice': 'Limited',
      'description': 'Data Pack',
      'category': 'data',
    },
    {
      'amount': 98,
      'validity': '7 Days',
      'data': '6GB',
      'voice': 'Limited',
      'description': 'Weekly Data Pack',
      'category': 'data',
    },
    {
      'amount': 149,
      'validity': '28 Days',
      'data': '12GB',
      'voice': 'Limited',
      'description': 'Monthly Data Pack',
      'category': 'data',
    },
  ];
  
  final Map<String, String> circleMap = {
    "DLT": "Delhi",
    "MUM": "Mumbai",
    "KOL": "Kolkata",
    "CHE": "Chennai",
    "BLR": "Bangalore",
    "HYD": "Hyderabad",
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOperators();
  }

  Future<void> _fetchOperators() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');

      if (token == null) {
        _useDefaultOperators();
        return;
      }

      final response = await http.post(
        Uri.parse('http://192.168.2.151:3000/api/recharge/operators'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result['success'] == true && result['operators'] != null) {
          setState(() {
            _operators = result['operators'];
            if (_operators.isNotEmpty) {
              selectedOperatorCode = _operators[0]['code']?.toString();
              selectedOperatorName = _operators[0]['description']?.toString();
            }
            _isLoading = false;
          });
          return;
        }
      }
      
      _useDefaultOperators();
      
    } catch (e) {
      print("Error: $e");
      _useDefaultOperators();
    }
  }
  
  void _useDefaultOperators() {
    setState(() {
      _operators = [
        {'code': 'AIR', 'description': 'Airtel'},
        {'code': 'JIO', 'description': 'Jio'},
        {'code': 'VOD', 'description': 'Vi'},
        {'code': 'BSNL', 'description': 'BSNL'},
      ];
      selectedOperatorCode = 'AIR';
      selectedOperatorName = 'Airtel';
      _isLoading = false;
    });
  }

  Future<void> _processRecharge(Map<String, dynamic> plan) async {
    setState(() => _isProcessing = true);
    
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken'); 

      if (token == null || token.isEmpty) {
        _showSnackBar("Please login again");
        return;
      }

      final response = await http.post(
        Uri.parse('http://192.168.2.151:3000/api/recharge'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", 
        },
        body: jsonEncode({
          "mobile": widget.mobile,
          "operator": selectedOperatorName,
          "circle": circleMap[selectedCircle] ?? selectedCircle,
          "amount": plan['amount'],
          "idempotencyKey": const Uuid().v4(),
          "testMode": true,
        }),
      ).timeout(const Duration(seconds: 15));

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        _showSnackBar("✅ Recharge Successful! ₹${plan['amount']}");
        Navigator.pop(context); 
      } else {
        _showSnackBar("Error: ${result['error'] ?? result['message']}");
      }
    } catch (e) {
      print("Recharge error: $e");
      _showSnackBar("Network Error: Could not reach server");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Recharge"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildOperatorCircleRow(),
              const SizedBox(height: 24),
              _buildTabs(),
              const SizedBox(height: 8),
              Expanded(child: _buildPlanList()),
            ],
          ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(Icons.phone_android, color: Color(0xFF2ECC71), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Recharge For",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  widget.mobile,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Prepaid",
              style: TextStyle(color: Color(0xFF2ECC71), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorCircleRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              label: "Operator",
              value: selectedOperatorName,
              items: _operators.map<String>((op) => op['description']?.toString() ?? "").toList(),
              onChanged: (value) {
                final selected = _operators.firstWhere(
                  (op) => op['description'] == value,
                  orElse: () => {},
                );
                setState(() {
                  selectedOperatorName = value;
                  selectedOperatorCode = selected['code']?.toString();
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdown(
              label: "Circle",
              value: circleMap[selectedCircle],
              items: circleMap.values.toList(),
              onChanged: (value) {
                final entry = circleMap.entries.firstWhere(
                  (entry) => entry.value == value,
                  orElse: () => const MapEntry("DLT", "Delhi"),
                );
                setState(() {
                  selectedCircle = entry.key;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label, style: const TextStyle(color: Colors.grey)),
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white),
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF2ECC71),
        labelColor: const Color(0xFF2ECC71),
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: "📱 Combo Plans", icon: Icon(Icons.local_offer)),
          Tab(text: "📊 Data Packs", icon: Icon(Icons.wifi)),
        ],
      ),
    );
  }

  Widget _buildPlanList() {
    final category = _tabController.index == 0 ? 'combo' : 'data';
    final filteredPlans = _plans.where((p) => p['category'] == category).toList();
    
    if (filteredPlans.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_cellular_alt, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text("No plans available", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredPlans.length,
      itemBuilder: (context, index) {
        final plan = filteredPlans[index];
        return _buildPlanCard(plan);
      },
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPaymentSheet(plan),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF2ECC71).withOpacity(0.3), const Color(0xFF2ECC71).withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      "₹${plan['amount']}",
                      style: const TextStyle(
                        color: Color(0xFF2ECC71),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['description'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildTag(Icons.timer_outlined, plan['validity']),
                          _buildTag(Icons.wifi, plan['data']),
                          _buildTag(Icons.call, plan['voice']),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  void _showPaymentSheet(Map<String, dynamic> plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withOpacity(0.1),
                borderRadius: BorderRadius.circular(35),
              ),
              child: const Icon(Icons.verified, color: Color(0xFF2ECC71), size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              "Confirm Payment",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.mobile,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    "Plan Amount",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₹${plan['amount']}",
                    style: const TextStyle(
                      color: Color(0xFF2ECC71),
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plan['validity'],
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: _isProcessing ? null : () {
                  Navigator.pop(context);
                  _processRecharge(plan);
                },
                child: _isProcessing 
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : const Text(
                      "PAY NOW",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}