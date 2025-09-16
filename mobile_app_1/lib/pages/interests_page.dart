import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/base_page.dart';

class InterestsPage extends StatefulWidget {
  const InterestsPage({super.key});

  @override
  State<InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends State<InterestsPage> {
  List<String> options = [];      // ตัวเลือกทั้งหมด
  List<String> selected = [];     // ตัวที่ผู้ใช้เลือก
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadInterests();
  }

  // ดึงตัวเลือกทั้งหมดจาก collection "interest"
  Future<void> _loadInterests() async {
    setState(() => _loading = true);
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection("interest").get();
      options = snapshot.docs.map((doc) => doc['name'] as String).toList();

      // ดึงข้อมูลผู้ใช้ปัจจุบัน
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final references = userDoc.data()?['interest'] as List<dynamic>?;

        // แปลง DocumentReference เป็นชื่อ
        selected = await _getInterests(references);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  // แปลง list ของ DocumentReference เป็นชื่อ
  Future<List<String>> _getInterests(List<dynamic>? references) async {
    if (references == null || references.isEmpty) return [];
    List<String> interestNames = [];
    for (var ref in references) {
      if (ref is DocumentReference) {
        final doc = await ref.get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null && data['name'] != null) {
            interestNames.add(data['name'] as String);
          }
        }
      }
    }
    return interestNames;
  }

  Future<void> _saveInterests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    try {
      setState(() => _loading = true);

      // แปลงชื่อกลับเป็น DocumentReference
      final interestRefs = await FirebaseFirestore.instance
          .collection('interest')
          .where('name', whereIn: selected)
          .get()
          .then((snap) => snap.docs.map((doc) => doc.reference).toList());

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({"interest": interestRefs}, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Interests saved")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Select Interests",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              children: options.map((interest) {
                return CheckboxListTile(
                  title: Text(interest),
                  value: selected.contains(interest),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selected.add(interest);
                      } else {
                        selected.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          ElevatedButton(
            onPressed: _saveInterests,
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
