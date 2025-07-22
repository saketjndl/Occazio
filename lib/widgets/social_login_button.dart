// File: lib/widgets/social_login_button.dart
import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final VoidCallback? onPressed; // Keep it nullable for disabling
  final IconData icon;
  final Color color; // Brand color
  final String label;

  const SocialLoginButton({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    this.onPressed, // Make onPressed nullable in constructor
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Using Option 1 style (subtle background) - Adjust if you preferred Option 2
    final buttonBackgroundColor = theme.brightness == Brightness.light
        ? color.withOpacity(0.08)
        : color.withOpacity(0.15);
    final borderColor = theme.brightness == Brightness.light
        ? color.withOpacity(0.3)
        : color.withOpacity(0.5);

    return ElevatedButton.icon(
      // Pass the onPressed value directly. ElevatedButton handles null correctly for disabling.
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonBackgroundColor,
        foregroundColor: color, // Icon/text color
        disabledBackgroundColor: buttonBackgroundColor.withOpacity(0.5), // Optional: Style when disabled
        disabledForegroundColor: color.withOpacity(0.5), // Optional: Style when disabled
        splashFactory: NoSplash.splashFactory, // Often looks cleaner
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: borderColor, width: 1),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}