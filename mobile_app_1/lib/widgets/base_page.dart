import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';

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
          appBar: showAppBar
              ? AppBar(
                  title: title != null ? Text(title!) : null,
                  backgroundColor: accessibility.highContrastMode 
                      ? Colors.white 
                      : Colors.white,
                  foregroundColor: accessibility.highContrastMode 
                      ? Colors.black 
                      : Colors.black,
                  elevation: 0,
                  actions: actions,
                )
              : null,
          backgroundColor: accessibility.highContrastMode 
              ? Colors.white 
              : Colors.white,
          body: child,
        );
      },
    );
  }
}


