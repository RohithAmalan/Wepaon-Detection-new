import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WeaponDetectionApp());
}

class WeaponDetectionApp extends StatelessWidget {
  const WeaponDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weapon Detection System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3dcc8c)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
