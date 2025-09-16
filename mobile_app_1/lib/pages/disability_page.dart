import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/base_page.dart';

class DisabilitiesPage extends StatefulWidget {
  const DisabilitiesPage({super.key});

  @override
  State<DisabilitiesPage> createState() => _DisabilitiesPageState();
}

class _DisabilitiesPageState extends State<DisabilitiesPage> {
  List<DocumentSnapshot> options = []; // all disability docs
  List<String> selectedIds = [];       // selected doc IDs
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadDisabilities();
  }

  Future<void> _loadDisabilities() async {
    setState(() => _loading = true);
    try {
      // Load all disability options
      final snapshot =
      await FirebaseFirestore.instance.collection("disability").get();
      options = snapshot.docs;

      // Load current user's disability IDs
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final references = userDoc.data()?['disability'] as List<dynamic>?;

        selectedIds = references
            ?.whereType<DocumentReference>()
            .map((ref) => ref.id)
            .toList() ??
            [];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error loading: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveDisabilities() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    try {
      setState(() => _loading = true);

      // Map selected IDs back to DocumentReference
      final disabilityRefs = options
          .where((doc) => selectedIds.contains(doc.id))
          .map((doc) => doc.reference)
          .toList();

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({"disability": disabilityRefs}, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Disabilities saved")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error saving: $e")));
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
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Select Disabilities",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              children: options.map((doc) {
                final id = doc.id;
                final name = doc['name'] as String? ?? id;

                return CheckboxListTile(
                  title: Text(name),
                  value: selectedIds.contains(id),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selectedIds.add(id);
                      } else {
                        selectedIds.remove(id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          ElevatedButton(
            onPressed: _saveDisabilities,
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
