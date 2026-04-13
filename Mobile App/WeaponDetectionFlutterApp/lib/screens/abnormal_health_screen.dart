import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class AbnormalHealthScreen extends StatefulWidget {
  final String videoUrl;
  final String takeActionTopic;
  final VoidCallback onBackToNormal;

  const AbnormalHealthScreen({
    super.key,
    required this.videoUrl,
    required this.takeActionTopic,
    required this.onBackToNormal,
  });

  @override
  State<AbnormalHealthScreen> createState() => _AbnormalHealthScreenState();
}

class _AbnormalHealthScreenState extends State<AbnormalHealthScreen> {
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('http://${widget.videoUrl}:8000/'));
  }

  Future<void> _publishMqttMessage(String payload) async {
    final client = MqttServerClient(
      'broker.hivemq.com',
      'flutter_action_${DateTime.now().millisecondsSinceEpoch}',
    );
    client.port = 1883;
    client.keepAlivePeriod = 30;
    client.logging(on: false);

    final connMsg = MqttConnectMessage()
        .withClientIdentifier('flutter_action_${DateTime.now().millisecondsSinceEpoch}')
        .startClean();
    client.connectionMessage = connMsg;

    try {
      await client.connect();
    } catch (e) {
      debugPrint('MQTT action connect error: $e');
      return;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);
      client.publishMessage(widget.takeActionTopic, MqttQos.atLeastOnce, builder.payload!);
      await Future.delayed(const Duration(milliseconds: 500));
      client.disconnect();
    }
  }

  void _triggerAlarm() => _publishMqttMessage('*');
  void _closeGate() => _publishMqttMessage('\$');

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Live camera feed via WebView
            SizedBox(
              height: screenHeight * 0.4,
              child: WebViewWidget(controller: _webViewController),
            ),

            // Red warning border
            Container(height: 5, color: Colors.red),

            // Alert content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Warning icon (replaces theft.png)
                    Container(
                      width: 160,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, size: 100, color: Colors.red),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'WEAPON IS DETECTED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _actionButton(label: 'ALARM ON', color: Colors.red, onPressed: _triggerAlarm),
                        const SizedBox(width: 16),
                        _actionButton(label: 'GATE CLOSE', color: Colors.red, onPressed: _closeGate),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Back to normal button
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: ElevatedButton(
                        onPressed: widget.onBackToNormal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'BACK TO NORMAL',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}
