import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Center(
        child: Image.asset(
          'assets/logo.png',
          height: 70,
        ),
      ),
    );
  }
}
