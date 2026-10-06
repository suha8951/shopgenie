import 'package:flutter/material.dart';
import '../models/scan_result.dart';
import '../services/api_service.dart';
import '../services/vision_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> {
  final _esp32Controller = TextEditingController();
  double _threshold = 0.78;
  bool _isScanning = false;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _esp32Controller.text = ApiService().esp32Url;
  }

  @override
  void dispose() {
    _esp32Controller.dispose();
    super.dispose();
  }

  Future<void> _triggerScan() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Connecting to ESP32-CAM stream & capturing frame...';
      _errorMessage = null;
    });

    try {
      final scanResult = await VisionService().matchFromEsp32(
        esp32Url: _esp32Controller.text.trim(),
        threshold: _threshold,
      );

      if (!mounted) return;
      setState(() => _isScanning = false);

      // Navigate to scan results screen
      Navigator.pushNamed(context, '/scan_results', arguments: scanResult);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _errorMessage = 'Scan error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32-CAM Vision Scanner'),
        actions: [
          CartBadgeButton(onTap: () => Navigator.pushNamed(context, '/cart')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Viewfinder Simulated / ESP32 preview card
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2321),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Reticle overlay
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isScanning ? AppTheme.accentAmber : AppTheme.primaryGreenLight,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  // Reticle corner accents
                  Positioned(
                    top: 24,
                    left: 24,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.primaryGreenLight, width: 3),
                          left: BorderSide(color: AppTheme.primaryGreenLight, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 24,
                    right: 24,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.primaryGreenLight, width: 3),
                          right: BorderSide(color: AppTheme.primaryGreenLight, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 24,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.primaryGreenLight, width: 3),
                          left: BorderSide(color: AppTheme.primaryGreenLight, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.primaryGreenLight, width: 3),
                          right: BorderSide(color: AppTheme.primaryGreenLight, width: 3),
                        ),
                      ),
                    ),
                  ),
                  // Status in center
                  if (_isScanning)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.accentAmber),
                        const SizedBox(height: 16),
                        Text(
                          _statusMessage ?? 'Analyzing with MobileNetV3...',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 48,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Place Product Under ESP32-CAM',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Branded item or loose commodity bag',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dangerRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.dangerRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.dangerRed, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Trigger Button
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _triggerScan,
              icon: _isScanning
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.flash_on_rounded),
              label: Text(_isScanning ? 'Processing Frame...' : 'Capture & Identify Item'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),

            // Manual Select Fallback Button
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/manual_selection'),
              icon: const Icon(Icons.touch_app_outlined),
              label: const Text('Manual Commodity Selection (No Camera)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 24),

            // ESP32 Settings Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Camera & Model Configuration',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _esp32Controller,
                    decoration: const InputDecoration(
                      labelText: 'ESP32-CAM Stream / Frame URL',
                      hintText: 'http://192.168.1.100:81/stream',
                      prefixIcon: Icon(Icons.wifi_outlined),
                    ),
                    onSubmitted: (val) => ApiService().setEsp32Url(val),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Similarity Threshold', style: TextStyle(fontSize: 13)),
                      Text(
                        '${(_threshold * 100).toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                  Slider(
                    value: _threshold,
                    min: 0.50,
                    max: 0.95,
                    divisions: 45,
                    activeColor: AppTheme.primaryGreen,
                    label: '${(_threshold * 100).toInt()}%',
                    onChanged: (val) {
                      setState(() => _threshold = val);
                    },
                  ),
                  const Text(
                    'Cosine threshold for MobileNetV3 matching. If lower than this or plain bag is detected, loose candidates will be presented.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
