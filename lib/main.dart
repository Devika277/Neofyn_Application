import 'package:flutter/material.dart';
import 'OnboardingScreen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init(); // Initialize StorageService
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NeoFyn',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000), // Pure Black
        primaryColor: const Color(0xFF2ECC71), // Emerald Green
      ),
      home: OnboardingScreen(),
    );
  }
}


