// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:my_app/screens/swipe.dart'; // <-- your CardSwipe page
import 'package:my_app/screens/community_home.dart';
import 'package:my_app/screens/create_post_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    // Ensure there is a user for Firestore security rules
    await FirebaseAuth.instance.signInAnonymously();
  } catch (_) {}
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Discover People',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const CommunityHome(),
        '/swipe': (context) => const CardSwipe(),
        '/createPost': (context) => const CreatePostPage(),
      },
      initialRoute: '/',
    );
  }
}
