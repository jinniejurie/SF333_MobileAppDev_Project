import 'package:flutter/material.dart';
import 'app_logo.dart';

class BasePage extends StatelessWidget {
  final Widget child;
  final bool showLogo;
  const BasePage({super.key, required this.child, this.showLogo = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF87CEFA), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (showLogo) const AppLogo(),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
