/// Text widget that adapts to accessibility settings.
/// 
/// Applies dynamic font scaling and high contrast colors when enabled.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';

/// A text widget that adapts to accessibility settings.
/// 
/// Automatically applies font scaling and high contrast colors
/// based on user's accessibility preferences.
class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AccessibleText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final theme = Theme.of(context);
    final baseStyle = style ?? theme.textTheme.bodyMedium;
    
    // Apply font scale
    final scaledStyle = baseStyle?.copyWith(
      fontSize: baseStyle.fontSize != null
          ? baseStyle.fontSize! * accessibility.fontScale
          : null,
    );

    // Apply high contrast colors if enabled
    final finalStyle = accessibility.highContrastMode
        ? scaledStyle?.copyWith(
            color: theme.colorScheme.onSurface,
          )
        : scaledStyle;

    return Text(
      text,
      style: finalStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

