import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class NormalHealthScreen extends StatefulWidget {
  final String ipAddress;

  const NormalHealthScreen({super.key, required this.ipAddress});

  @override
  State<NormalHealthScreen> createState() => _NormalHealthScreenState();
}

class _NormalHealthScreenState extends State<NormalHealthScreen> {
  late final WebViewController _webViewController;
  int _crowdCount = 0;
  String _status = 'SAFE';
  bool _loadingStatus = true;

  @override
  void initState() {
    super.initState();

    // Load live MJPEG stream
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('http://${widget.ipAddress}:8000/video_feed'));

    _pollStatus();
  }

  /// Poll /api/status every 2 seconds for crowd count & threat level
  Future<void> _pollStatus() async {
    while (mounted) {
      try {
        final response = await http
            .get(Uri.parse('http://${widget.ipAddress}:8000/api/status'))
            .timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              _crowdCount = data['crowd_count'] ?? 0;
              _status = data['level'] ?? 'SAFE';
              _loadingStatus = false;
            });
          }
        }
      } catch (_) {
        if (mounted) setState(() => _loadingStatus = false);
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Color get _statusColor {
    switch (_status) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      default:
        return const Color(0xFF3dcc8c);
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case 'HIGH':
        return Icons.warning_amber_rounded;
      case 'MEDIUM':
        return Icons.warning_outlined;
      default:
        return Icons.shield;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0f1117),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Icon(_statusIcon, color: _statusColor, size: 26),
                  const SizedBox(width: 10),
                  const Text(
                    'LIVE MONITORING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _statusColor, width: 1),
                    ),
                    child: Text(
                      _loadingStatus ? '...' : _status,
                      style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Live Camera WebView ──
            Container(
              height: size.height * 0.42,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _statusColor.withOpacity(0.5), width: 2),
                color: Colors.black,
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  WebViewWidget(controller: _webViewController),
                  // LIVE badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          SizedBox(width: 5),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Status Cards ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _statCard(
                    icon: Icons.people_outline,
                    label: 'Crowd Count',
                    value: _loadingStatus ? '--' : '$_crowdCount',
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    icon: _statusIcon,
                    label: 'Threat Level',
                    value: _loadingStatus ? '--' : _status,
                    color: _statusColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Detection Status Banner ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3dcc8c).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF3dcc8c).withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Color(0xFF3dcc8c), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NO ASSAULT DETECTED',
                            style: TextStyle(
                              color: Color(0xFF3dcc8c),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'System is actively monitoring. All clear.',
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
