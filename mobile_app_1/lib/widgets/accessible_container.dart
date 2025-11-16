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
        BoxDecoration? finalDecoration;

        // Apply high contrast mode
        if (accessibility.highContrastMode) {
          // In high contrast mode, always use white background with thick black border
          if (decoration != null) {
            // Copy all properties except gradient, and set color to white with thick border
            finalDecoration = BoxDecoration(
              color: Colors.white,
              borderRadius: decoration!.borderRadius,
              border: decoration!.border != null
                  ? Border.all(
                      color: Colors.black,
                      width: 3, // Thick border for high contrast
                    )
                  : Border.all(
                      color: Colors.black,
                      width: 3, // Thick border for high contrast
                    ),
              boxShadow: null, // Remove shadows in high contrast mode
              shape: decoration!.shape,
            );
          } else {
            // If no decoration, use white background with thick black border
            finalDecoration = BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.black,
                width: 3, // Thick border for high contrast
              ),
            );
          }
        } else {
          // Normal mode - use original decoration
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
}

