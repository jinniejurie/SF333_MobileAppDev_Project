/// Container widget that adapts to accessibility settings.
/// 
/// Automatically applies high contrast mode styling (white background with
/// thick black borders) when enabled. Removes gradients and shadows in
/// high contrast mode for better visibility.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';

/// A container that adapts its decoration based on accessibility settings.
/// 
/// In high contrast mode, replaces gradients with white backgrounds and
/// adds thick black borders. Removes shadows for better contrast.
class AccessibleContainer extends StatelessWidget {
  final Widget child;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const AccessibleContainer({
    super.key,
    required this.child,
    this.decoration,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, accessibility, _) {
        BoxDecoration? finalDecoration;

        // Apply high contrast mode transformations
        if (accessibility.highContrastMode) {
          finalDecoration = _buildHighContrastDecoration(decoration);
        } else {
          finalDecoration = decoration;
        }

        return Container(
          decoration: finalDecoration,
          padding: padding,
          margin: margin,
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          alignment: alignment,
          child: child,
        );
      },
    );
  }

  /// Builds a high contrast decoration with white background and thick black border.
  BoxDecoration _buildHighContrastDecoration(BoxDecoration? decoration) {
    const thickBlackBorder = BorderSide(color: Colors.black, width: 3);
    
    if (decoration != null) {
      return BoxDecoration(
        color: Colors.white,
        borderRadius: decoration.borderRadius,
        border: Border.all(
          color: Colors.black,
          width: 3, // Thick border for high contrast
        ),
        boxShadow: null, // Remove shadows in high contrast mode
        shape: decoration.shape,
      );
    } else {
      return const BoxDecoration(
        color: Colors.white,
        border: Border.fromBorderSide(thickBlackBorder),
      );
    }
  }
}

