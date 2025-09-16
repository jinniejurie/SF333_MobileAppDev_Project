import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/home_page.dart';
import 'pages/signup_page.dart';
import 'pages/login_page.dart';
import 'pages/disability_page.dart';
import 'pages/interests_page.dart';
import 'pages/final_profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My App',
      initialRoute: '/',
      routes: {
        '/': (context) => InterestsPage(),
        '/signup': (context) => SignUpPage(),  // ลบ const ออก
        '/login': (context) => const LoginPage(),
        '/disability': (context) => const DisabilityPage(),
        '/interests': (context) => const HomePage(),
        '/final': (context) => const FinalProfilePage(),
      },
    );
  }
}
