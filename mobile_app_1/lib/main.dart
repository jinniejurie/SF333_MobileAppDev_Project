import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'test_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppEntry());
}

class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const FirebaseInitializer(),
    );
  }
}

/// Widget รอ Firebase init
class FirebaseInitializer extends StatefulWidget {
  const FirebaseInitializer({super.key});

  @override
  State<FirebaseInitializer> createState() => _FirebaseInitializerState();
}

class _FirebaseInitializerState extends State<FirebaseInitializer> {
  late Future<FirebaseApp> _firebaseInitFuture;

  @override
  void initState() {
    super.initState();
    _firebaseInitFuture = _initializeFirebase();
  }

  Future<FirebaseApp> _initializeFirebase() async {
    try {
      print("Before Firebase initialize");
      FirebaseApp app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("After Firebase initialize"); // <- ดูว่าขึ้นหรือไม่
      return app;
    } catch (e, st) {
      print("Firebase init error: $e");
      print(st);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _firebaseInitFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // แสดง splash/loading ระหว่างรอ init
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          // แสดง error UI ถ้า Firebase init fail
          return Scaffold(
            body: Center(
              child: Text('Firebase initialization error: ${snapshot.error}'),
            ),
          );
        } else {
          // Firebase init เสร็จแล้ว → ไปหน้า TestPage
          return const TestPage();
        }
      },
    );
  }
}
