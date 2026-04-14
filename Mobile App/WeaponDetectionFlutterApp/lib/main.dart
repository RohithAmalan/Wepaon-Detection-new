import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/login_screen.dart';

// ── Global notification plugin instance ──
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

/// Show a system push notification for weapon detection
Future<void> showWeaponAlert({String level = 'HIGH', String description = 'Weapon Detected'}) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'weapon_alerts',
    'Weapon Alerts',
    channelDescription: 'Real-time weapon detection alerts',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    icon: '@mipmap/ic_launcher',
  );
  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  const NotificationDetails notifDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );
  await flutterLocalNotificationsPlugin.show(
    0,
    '⚠️ WEAPON DETECTED — $level THREAT',
    description,
    notifDetails,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  runApp(const WeaponDetectionApp());
}

class WeaponDetectionApp extends StatelessWidget {
  const WeaponDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentinel Guard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A2E),
          elevation: 0,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
