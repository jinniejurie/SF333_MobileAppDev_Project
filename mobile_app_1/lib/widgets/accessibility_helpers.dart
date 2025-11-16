import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';

/// Helper class for accessibility color management
class AccessibilityHelpers {
  /// Get background color based on high contrast mode
  static Color getBackgroundColor(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    return accessibility.highContrastMode ? Colors.white : const Color(0xFFD6F0FF);
  }

  /// Get card color based on high contrast mode
  static Color getCardColor(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    return accessibility.highContrastMode ? Colors.white : Colors.white;
  }

  /// Get primary button color based on high contrast mode
  static Color getPrimaryButtonColor(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    return accessibility.highContrastMode ? Colors.black : const Color(0xFF90CAF9);
  }

  /// Get border color based on high contrast mode
  static Color getBorderColor(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    return accessibility.highContrastMode ? Colors.black : Colors.grey[300]!;
  }

  /// Get gradient or solid color based on high contrast mode
  static BoxDecoration getBackgroundDecoration(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    if (accessibility.highContrastMode) {
      return const BoxDecoration(color: Colors.white);
    } else {
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD6F0FF), Color(0xFFEFF4FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
    }
  }

  /// Get text color based on high contrast mode
  static Color getTextColor(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    return accessibility.highContrastMode ? Colors.black : Colors.black;
  }

  /// Get shadow based on high contrast mode
  static List<BoxShadow> getShadow(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    if (accessibility.highContrastMode) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      return const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ];
    }
  }
}

