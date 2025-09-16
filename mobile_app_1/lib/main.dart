import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/home_page.dart';
import 'pages/signup_page.dart';
import 'pages/login_page.dart';
import 'pages/disability_page.dart';
import 'pages/interests_page.dart'; // <-- เพิ่มบรรทัดนี้
import 'pages/final_profile_page.dart'; // <-- เพิ่มบรรทัดนี้


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // ✅ อย่าลืม init Firebase
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
        '/': (context) => const HomePage(),
        '/signup': (context) => const SignUpPage(),
        '/login': (context) => const LoginPage(),
        '/disability': (context) => const DisabilitiesPage(), // ✅ ใช้ชื่อ class นี้
        '/interests': (context) => InterestsPage(),
        '/final': (context) => const FinalProfilePage(),

      }, // <-- เอา comma หลังวงเล็บปิดออก หรือปล่อยก็ได้
    );
  }
}
