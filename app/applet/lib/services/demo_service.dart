import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized manager for Demo Mode.
///
/// Ensures Demo Mode is only accessible in development/debug builds (via [kDebugMode]),
/// keeps demo state separated from real API sessions, and provides helper methods
/// to block destructive actions with user-friendly explanations.
class DemoService extends ChangeNotifier {
  static final DemoService _instance = DemoService._internal();
  factory DemoService() => _instance;
  DemoService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool _isDemoMode = false;

  /// Returns true only if Demo Mode is toggled ON AND the application is running
  /// in development / debug mode. In release builds, this is always false.
  bool get isDemoMode => _isDemoMode && kDebugMode;

  /// Enters Demo Mode without requiring real credentials.
  /// Strictly rejected in release builds.
  void enterDemoMode() {
    if (!kDebugMode) return;
    _isDemoMode = true;
    notifyListeners();
  }

  /// Exits Demo Mode and clears demo state.
  void exitDemo() {
    _isDemoMode = false;
    notifyListeners();
  }

  /// Shows an informative dialog explaining that a destructive or production action
  /// cannot be performed while in Demo Mode and requires a real login.
  void showDemoActionDisabledDialog(
    BuildContext context, {
    required String actionName,
    String? customExplanation,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('Demo Mode: Action Disabled', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          customExplanation ??
              '$actionName is disabled while exploring in Demo Mode.\n\n'
              'To prevent modifying live store inventory, billing records, or staff rosters, '
              'a real authenticated shopkeeper login is required.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK, Understood'),
          ),
        ],
      ),
    );
  }
}
