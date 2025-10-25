import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: title != null ? Text(title!) : null,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              actions: actions,
            )
          : null,
      backgroundColor: Colors.white,
      body: child,
    );
  }
}
