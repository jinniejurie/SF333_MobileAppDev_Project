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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    setState(() => _loading = true);
    try {
      // ดึงตัวเลือกทั้งหมดจาก collection "interest"
      final snapshot = await FirebaseFirestore.instance.collection("interest").get();
      options = snapshot.docs.map((doc) => doc['name'] as String).toList();

      // ดึงข้อมูลผู้ใช้ปัจจุบัน
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final rawReferences = userDoc.data()?['interest'] as List<dynamic>?;

        // แปลง DocumentReference หรือ path string เป็นชื่อ
        selected = await _getInterests(rawReferences);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error loading interests: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<String>> _getInterests(List<dynamic>? references) async {
    if (references == null || references.isEmpty) return [];

    List<String> interestNames = [];

    for (var ref in references) {
      try {
        DocumentReference docRef;

        if (ref is DocumentReference) {
          docRef = ref;
        } else if (ref is String) {
          // ถ้าเป็น string path ให้แปลงเป็น DocumentReference
          docRef = FirebaseFirestore.instance.doc(ref);
        } else {
          debugPrint('⚠️ Skipped invalid interest reference: $ref');
          continue;
        }

        final doc = await docRef.get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null && data['name'] != null) {
            interestNames.add(data['name'] as String);
          }
        }
      } catch (e) {
        debugPrint('❌ Error reading interest: $e');
      }
    }

    return interestNames;
  }

  Future<void> _saveInterests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() => _loading = true);

      // แปลงชื่อกลับเป็น DocumentReference
      final interestRefs = await FirebaseFirestore.instance
          .collection('interest')
          .where('name', whereIn: selected.isEmpty ? [''] : selected)
          .get()
          .then((snap) => snap.docs.map((doc) => doc.reference).toList());

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({"interest": interestRefs}, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Interests saved")));
        Navigator.pushNamed(context, '/final'); // ไปหน้าถัดไป
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error saving interests: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            "Select Interests",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((o) {
                final sel = selected.contains(o);
                return ChoiceChip(
                  label: Text(o),
                  selected: sel,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        selected.add(o);
                      } else {
                        selected.remove(o);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _saveInterests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Next →'),
            ),
          ),
        ],
      ),
    );
  }
}
