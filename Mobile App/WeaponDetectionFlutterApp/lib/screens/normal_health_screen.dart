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
  // Camera feed 0 = Laptop, 1 = iPhone
  int _selectedCam = 0;
  late WebViewController _webViewController;

  int _crowdCount = 0;
  String _status = 'SAFE';
  bool _loadingStatus = true;
  bool _notificationSentForCurrentThreat = false;

  static const _camLabels = ['Main Entrance', 'Back Gate'];
  static const _feedPaths = ['video_feed', 'video_feed/1'];

  // ── Light theme colours ──
  static const _bg        = Color(0xFFF5F7FA);
  static const _card      = Colors.white;
  static const _textPrim  = Color(0xFF1A1A2E);
  static const _textSub   = Color(0xFF6B7280);
  static const _safe      = Color(0xFF10B981);
  static const _accent    = Color(0xFF1A73E8);

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
      ..setBackgroundColor(Colors.black)
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

            // Trigger notification and navigate when threat detected
            if ((newStatus == 'HIGH' || newStatus == 'MEDIUM') && !_notificationSentForCurrentThreat) {
              _notificationSentForCurrentThreat = true;
              // Fire system notification
              showWeaponAlert(level: newStatus, description: desc);
              // Navigate to emergency screen
              widget.onThreatDetected();
            }

            // Reset flag when system goes back to SAFE
            if (newStatus == 'SAFE') {
              _notificationSentForCurrentThreat = false;
            }

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
      case 'HIGH':    return Colors.red;
      case 'MEDIUM':  return Colors.orange;
      default:        return _safe;
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case 'HIGH':    return Icons.warning_amber_rounded;
      case 'MEDIUM':  return Icons.warning_outlined;
      default:        return Icons.shield_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.videocam_outlined, color: _accent, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Live Monitoring',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrim)),
                      Text('Real-time threat detection',
                        style: TextStyle(fontSize: 12, color: _textSub)),
                    ],
                  ),
                  const Spacer(),
                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _statusColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon, size: 14, color: _statusColor),
                        const SizedBox(width: 5),
                        Text(
                          _loadingStatus ? '...' : _status,
                          style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Camera Selector ──
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EEF6),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
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
                            color: selected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: selected ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam, size: 14,
                                color: selected ? _accent : _textSub),
                              const SizedBox(width: 5),
                              Text(_camLabels[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? _accent : _textSub,
                                )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 12),

              // ── Live Camera Feed ──
              Container(
                height: size.height * 0.38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _statusColor.withOpacity(0.4), width: 2),
                  color: Colors.black,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0,4))],
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
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
                            Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    // CAM label badge
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('CAM ${_selectedCam + 1}',
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Stats Cards ──
              Row(
                children: [
                  _statCard(
                    icon: Icons.people_alt_outlined,
                    label: 'Crowd',
                    value: _loadingStatus ? '--' : '$_crowdCount people',
                    color: _accent,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    icon: _statusIcon,
                    label: 'Threat',
                    value: _loadingStatus ? '--' : _status,
                    color: _statusColor,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Status Banner ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _safe.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _safe.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _safe.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline, color: _safe, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NO THREAT DETECTED',
                            style: TextStyle(color: _safe, fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 2),
                          Text('System is actively scanning all camera feeds.',
                            style: TextStyle(color: _textSub, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({required IconData icon, required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: _textSub, fontSize: 12)),
            const SizedBox(height: 3),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
