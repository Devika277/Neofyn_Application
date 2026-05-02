import 'package:flutter/material.dart';
import 'package:my_app/services/Recharges/mobileNumberScreen.dart';
import 'package:my_app/screens/bbps_payment_screen.dart'; // ← add this import



class RechargeCategoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> categories = [
    {"name": "Mobile Recharge", "icon": Icons.phone_android, "type": "mobile", "categoryId": "mobile", "emoji": "📱"},
    {"name": "DTH Recharge",    "icon": Icons.tv,            "type": "dth", "categoryId": "dth", "emoji": "📡"},
    {"name": "Fastag",          "icon": Icons.directions_car, "type": "fastag", "categoryId": "fastag", "emoji": "🚗"},
    {"name": "Electricity",     "icon": Icons.lightbulb,     "type": "electricity", "categoryId": "ELECTRICITY", "emoji": "⚡"},
    {"name": "Postpaid",        "icon": Icons.description,   "type": "postpaid", "categoryId": "POSTPAID", "emoji": "📱"},
    {"name": "Loan Repayment",  "icon": Icons.account_balance, "type": "loan", "categoryId": "LOAN", "emoji": "🏦"},
    {"name": "Water Bill",      "icon": Icons.water_drop,    "type": "water", "categoryId": "WATER", "emoji": "💧"},
    {"name": "Gas Bill",        "icon": Icons.fireplace,     "type": "gas", "categoryId": "GAS", "emoji": "🔥"},
    {"name": "Insurance",       "icon": Icons.shield,        "type": "insurance", "categoryId": "INSURANCE", "emoji": "🛡️"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Recharge & Bill Pay",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Select Category',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _onTap(context, category),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Use emoji instead of Icon for consistent style with BBPS screen
                        Text(
                          category['emoji']!,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['name']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, Map<String, dynamic> category) {
    final String type = category['type']!;
    final String categoryId = category['categoryId']!;
    final String categoryName = category['name']!;

    switch (type) {
      case 'mobile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MobileNumberScreen(),
          ),
        );
        break;

      case 'electricity':
      case 'water':
      case 'gas':
      case 'dth':
      case 'fastag':
      case 'postpaid':
      case 'loan':
      case 'insurance':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BBPSPaymentScreen(
              preselectedCategory: categoryId,
              categoryName: categoryName,
              categoryEmoji: category['emoji'],
            ),
          ),
        );
        break;
    }
  }
}