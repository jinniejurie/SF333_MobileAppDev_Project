import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';

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
        final theme = Theme.of(context);

        BoxDecoration? finalDecoration = decoration;

        // Apply high contrast mode to gradients
        if (accessibility.highContrastMode && decoration?.gradient != null) {
          finalDecoration = decoration?.copyWith(
            gradient: null,
            color: Colors.white,
          );
        } else if (accessibility.highContrastMode && decoration?.color == null) {
          // If no gradient but high contrast, use white background
          finalDecoration = (decoration ?? const BoxDecoration()).copyWith(
            color: Colors.white,
          );
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
}

