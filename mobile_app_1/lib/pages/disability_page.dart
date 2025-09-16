import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/base_page.dart';

class DisabilityPage extends StatefulWidget {
  const DisabilityPage({super.key});

  @override
  State<DisabilityPage> createState() => _DisabilityPageState();
}

class _DisabilityPageState extends State<DisabilityPage> {
  List<String> options = []; // ชื่อ disability ทั้งหมด
  List<String> selected = []; // ชื่อ disability ที่เลือก
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDisabilities();
  }

  Future<void> _loadDisabilities() async {
    setState(() => _loading = true);
    try {
      // ดึงตัวเลือกทั้งหมดจาก collection "disability"
      final snapshot =
      await FirebaseFirestore.instance.collection("disability").get();
      options = snapshot.docs.map((doc) => doc['name'] as String? ?? doc.id).toList();

      // ดึงข้อมูลผู้ใช้ปัจจุบัน
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        // ดึงฟิลด์ disability เป็น List<DocumentReference>
        final references = userDoc.data()?['disability'] as List<dynamic>?;

        // แปลง DocumentReference เป็นชื่อ
        if (references != null) {
          selected = [];
          for (var ref in references) {
            if (ref is DocumentReference) {
              final doc = await ref.get();
              if (doc.exists && doc.data() != null) {
                final data = doc.data() as Map<String, dynamic>;
                selected.add(data['name'] as String);
              }
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading disabilities: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveDisabilities() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() => _loading = true);

      // แปลงชื่อกลับเป็น DocumentReference
      final disabilityRefs = await FirebaseFirestore.instance
          .collection('disability')
          .where('name', whereIn: selected.isEmpty ? [''] : selected)
          .get()
          .then((snap) => snap.docs.map((doc) => doc.reference).toList());

      // บันทึกลง firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({"disability": disabilityRefs}, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Disabilities saved")),
        );
        Navigator.pushNamed(context, '/interests'); // ไปหน้าต่อไป
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving disabilities: $e")),
        );
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
            "How can we support your needs?",
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
              onPressed: _saveDisabilities,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Next →'),
            ),
          )
        ],
      ),
    );
  }
}
