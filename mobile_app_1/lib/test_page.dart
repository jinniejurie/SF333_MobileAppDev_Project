// test_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/event_list_page.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Firestore Test")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  // เขียนข้อมูลลง Firestore
                  await FirebaseFirestore.instance
                      .collection('test')
                      .doc('hello')
                      .set({'message': 'Hello Firebase!'});

                  // อ่านข้อมูลจาก Firestore
                  final doc = await FirebaseFirestore.instance
                      .collection('test')
                      .doc('hello')
                      .get();

                  final msg = doc['message'];

                  print("Firestore Test: $msg");

                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Message: $msg")));
                } catch (e) {
                  print("Error: $e");
                }
              },
              child: const Text("Test Firestore"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EventListPage()),
                );
              },
              child: const Text('ไปหน้า Event List'),
            ),
          ],
        ),
      ),
    );
  }
}
