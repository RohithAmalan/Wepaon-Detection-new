import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import '../main.dart' show showWeaponAlert;

class NormalHealthScreen extends StatefulWidget {
  final String ipAddress;
  final VoidCallback onThreatDetected;

  const NormalHealthScreen({
    super.key,
    required this.ipAddress,
    required this.onThreatDetected,
  });

  @override
  State<NormalHealthScreen> createState() => _NormalHealthScreenState();
}

class _NormalHealthScreenState extends State<NormalHealthScreen> {
  int _selectedCam = 0;
  late WebViewController _webViewController;

  int _crowdCount = 0;
  String _status = 'SAFE';
  bool _loadingStatus = true;
  bool _notificationSentForCurrentThreat = false;

  // Same theme as Login page
  static const _gradBegin = Color(0xFF1a1a2e);
  static const _gradMid   = Color(0xFF16213e);
  static const _gradEnd   = Color(0xFF0f3460);
  static const _green     = Color(0xFF3dcc8c);
  static const _cardBg    = Color(0x1AFFFFFF); // white 10%
  static const _textSub   = Colors.white54;

  static const _camLabels = ['Main Entrance', 'Back Gate (iPhone)'];
  static const _feedPaths = ['video_feed', 'video_feed/1'];

  @override
  void initState() {
    super.initState();
    _initWebView(_selectedCam);
    _pollStatus();
  }

  void _initWebView(int camIndex) {
    final url = 'http://${widget.ipAddress}:8000/${_feedPaths[camIndex]}';
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadRequest(Uri.parse(url));
  }

  void _switchCamera(int idx) {
    if (idx == _selectedCam) return;
    setState(() {
      _selectedCam = idx;
      _initWebView(idx);
    });
  }

  Future<void> _pollStatus() async {
    while (mounted) {
      try {
        final response = await http
            .get(Uri.parse('http://${widget.ipAddress}:8000/api/status'))
            .timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (mounted) {
            final newStatus = data['level'] ?? 'SAFE';
            final newCount  = data['crowd_count'] ?? 0;
            final desc      = data['description'] ?? 'Weapon Detected';

            if ((newStatus == 'HIGH' || newStatus == 'MEDIUM') &&
                !_notificationSentForCurrentThreat) {
              _notificationSentForCurrentThreat = true;
              showWeaponAlert(level: newStatus, description: desc);
              widget.onThreatDetected();
            }
            if (newStatus == 'SAFE') _notificationSentForCurrentThreat = false;

            setState(() {
              _status = newStatus;
              _crowdCount = newCount;
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
      case 'HIGH':    return Colors.redAccent;
      case 'MEDIUM':  return Colors.orange;
      default:        return _green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradBegin, _gradMid, _gradEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: _green.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.security, color: _green, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SENTINEL', style: TextStyle(color: Colors.white, fontSize: 18,
                            fontWeight: FontWeight.bold, letterSpacing: 2)),
                        Text('Live Threat Monitoring', style: TextStyle(color: _textSub, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                    // Status pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        _loadingStatus ? '...' : _status,
                        style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Camera Tab Selector ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: List.generate(_camLabels.length, (i) {
                      final selected = i == _selectedCam;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _switchCamera(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: selected ? _green.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              border: selected
                                  ? Border.all(color: _green.withOpacity(0.6))
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.videocam, size: 13,
                                    color: selected ? _green : Colors.white38),
                                const SizedBox(width: 5),
                                Text(_camLabels[i],
                                    style: TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w600,
                                      color: selected ? _green : Colors.white38,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Live Camera Feed (fills remaining space) ──
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _statusColor.withOpacity(0.5), width: 2),
                      color: Colors.black,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // WebView fills entire container
                        WebViewWidget(controller: _webViewController),

                        // LIVE badge
                        Positioned(
                          top: 10, left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, color: Colors.white, size: 7),
                                SizedBox(width: 4),
                                Text('LIVE', style: TextStyle(
                                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),

                        // CAM label + hint for CAM 2
                        Positioned(
                          top: 10, right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('CAM ${_selectedCam + 1}',
                                style: const TextStyle(color: Colors.white70, fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),

                        // Hint for iPhone camera tab
                        if (_selectedCam == 1)
                          Positioned(
                            bottom: 12, left: 0, right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black70,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '📱 Install "IP Webcam" on iPhone → add IP to streams.txt',
                                  style: TextStyle(color: Colors.white60, fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Stats Row ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _statCard(
                      icon: Icons.people_alt_outlined,
                      label: 'Crowd Count',
                      value: _loadingStatus ? '--' : '$_crowdCount',
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      icon: Icons.shield_outlined,
                      label: 'Threat Level',
                      value: _loadingStatus ? '--' : _status,
                      valueColor: _statusColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Status Banner ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: _green, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NO THREAT DETECTED',
                              style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(height: 2),
                            Text('All cameras are actively being monitored.',
                              style: TextStyle(color: _textSub, fontSize: 11)),
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
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _green, size: 20),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: _textSub, fontSize: 11)),
            const SizedBox(height: 3),
            Text(value, style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
