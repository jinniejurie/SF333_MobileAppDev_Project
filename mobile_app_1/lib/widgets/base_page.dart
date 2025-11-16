/// Base page widget with consistent styling and accessibility support.
/// 
/// Provides a standard Scaffold with AppBar that adapts to accessibility settings.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';

/// A base page widget with consistent AppBar and background styling.
/// 
/// Automatically adapts to high contrast mode. Used as a base for
/// pages that need a simple scaffold with optional AppBar.
class BasePage extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showAppBar;
  final List<Widget>? actions;

  const BasePage({
    super.key,
    required this.child,
    this.title,
    this.showAppBar = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, accessibility, _) {
        return Scaffold(
          appBar: showAppBar ? _buildAppBar(accessibility, title, actions) : null,
          backgroundColor: Colors.white,
          body: child,
        );
      },
    );
  }

  /// Builds the AppBar with accessibility-aware styling.
  AppBar _buildAppBar(
    AccessibilityProvider accessibility,
    String? title,
    List<Widget>? actions,
  ) {
    return AppBar(
      title: title != null ? Text(title) : null,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      actions: actions,
    );
  }
}


