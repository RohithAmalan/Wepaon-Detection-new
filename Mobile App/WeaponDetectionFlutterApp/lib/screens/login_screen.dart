import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'normal_health_screen.dart';
import 'abnormal_health_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _flag = 0; // 0=login, 1=normal, 2=weapon detected

  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();

  String _ipAddress = '';
  String _notiTopic = '';
  String _shopTopic = '';
  bool _isLoading = false;

  MqttServerClient? _mqttClient;

  @override
  void dispose() {
    _mqttClient?.disconnect();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _ipCtrl.dispose();
    super.dispose();
  }

  /// Calls the backend /api/login endpoint
  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final ip = _ipCtrl.text.trim();

    if (username.isEmpty || password.isEmpty || ip.isEmpty) {
      _showAlert('Please enter Username, Password and IP Address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse('http://$ip:8000/api/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['status'] == 'success') {
        final topics = body['topics'] as Map<String, dynamic>;
        final notiTopic = topics['notification'] as String;
        final shopTopic = topics['shop'] as String;

        // Save IP for later use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ipaddress', ip);

        setState(() {
          _ipAddress = ip;
          _notiTopic = notiTopic;
          _shopTopic = shopTopic;
          _flag = 1;
          _isLoading = false;
        });

        // Connect MQTT to listen for weapon alerts
        await _connectMqtt(shopTopic);
      } else {
        setState(() => _isLoading = false);
        _showAlert(body['message'] ?? 'Login failed. Check credentials.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showAlert(
        'Could not reach server at $ip:8000\n\nMake sure:\n• detect.py is running\n• iPhone & Mac are on the same Wi-Fi',
      );
    }
  }

  Future<void> _connectMqtt(String shopTopic) async {
    final client = MqttServerClient(
      'broker.hivemq.com',
      'flutter_weapon_${DateTime.now().millisecondsSinceEpoch}',
    );
    client.port = 1883;
    client.keepAlivePeriod = 60;
    client.logging(on: false);
    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_weapon_${DateTime.now().millisecondsSinceEpoch}')
        .startClean();

    try {
      await client.connect();
    } catch (e) {
      debugPrint('MQTT connect error: $e');
      return;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      debugPrint('MQTT connected');
      _mqttClient = client;
      client.subscribe(shopTopic, MqttQos.atMostOnce);
      client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> msgs) {
        final recMess = msgs[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );
        debugPrint('MQTT message: $payload');
        if (payload != '0' && mounted) {
          setState(() => _flag = 2);
        }
      });
    }
  }

  void _backToNormal() => setState(() => _flag = 1);

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_flag == 1) {
      return NormalHealthScreen(
        ipAddress: _ipAddress,
        onThreatDetected: () => setState(() => _flag = 2),
      );
    }
    if (_flag == 2) {
      return AbnormalHealthScreen(
        videoUrl: _ipAddress,
        takeActionTopic: _notiTopic,
        onBackToNormal: _backToNormal,
      );
    }

    // ── Login Screen ──
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3dcc8c).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF3dcc8c), width: 2),
                    ),
                    child: const Icon(Icons.security, size: 48, color: Color(0xFF3dcc8c)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'WEAPON DETECTION',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Secure Login',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  _inputField(
                    controller: _usernameCtrl,
                    hint: 'Username',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _inputField(
                    controller: _passwordCtrl,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    obscure: true,
                  ),
                  const SizedBox(height: 16),
                  _inputField(
                    controller: _ipCtrl,
                    hint: 'Server IP Address (e.g. 192.168.1.10)',
                    icon: Icons.wifi,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3dcc8c),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 6,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'LOGIN',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF3dcc8c), size: 22),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
