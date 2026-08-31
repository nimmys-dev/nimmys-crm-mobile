import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nimmys_crm/utils/app_colors.dart';
import 'package:nimmys_crm/utils/app_global_variables.dart';
import 'package:nimmys_crm/utils/app_text_style.dart';

class ToastMessages {
  ToastMessages._();

  static const Duration _duration = Duration(seconds: 3);
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  /// Remove any currently visible toast
  static void _dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
    _timer?.cancel();
    _timer = null;
  }

  /// Show a toast using an OverlayEntry (does not block the back button)
  static void _show(Widget child) {
    _dismiss(); // remove previous toast

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 16,
        left: 16,
        right: 16,
        child: Material(color: Colors.transparent, child: child),
      ),
    );

    overlay.insert(_currentEntry!);

    // Auto‑dismiss after the duration
    _timer = Timer(_duration, _dismiss);
  }

  // ---------------------------------------------------------------------
  // Public methods – same signatures as before
  // ---------------------------------------------------------------------

  static void internetError({required String message}) {
    _show(
      _buildToast(
        message: message,
        icon: Icons.wifi_off_rounded,
        iconColor: AppColors.secondaryColor,
      ),
    );
  }

  static void success({required String message}) {
    _show(
      _buildToast(
        message: message,
        icon: Icons.check_circle_rounded,
        iconColor: Colors.green,
      ),
    );
  }

  static void error({required String message}) {
    _show(
      _buildToast(message: message, icon: Icons.error, iconColor: Colors.red),
    );
  }

  static void alert({required String message}) {
    _show(
      _buildToast(
        message: message,
        icon: Icons.error,
        iconColor: Colors.orange,
      ),
    );
  }

  static void custom({required String message}) {
    _show(
      _buildToast(
        message: message,
        icon: Icons.warning_rounded,
        iconColor: AppColors.secondaryColor,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Visual builder – matches your old Flushbar design
  // ---------------------------------------------------------------------

  static Widget _buildToast({
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 3),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 25),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppTextStyle.body)),
        ],
      ),
    );
  }
}
