import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FinalProfilePage extends StatefulWidget {
  const FinalProfilePage({super.key});

  @override
  State<FinalProfilePage> createState() => _FinalProfilePageState();
}

class _FinalProfilePageState extends State<FinalProfilePage> {
  bool _loading = true;
  Map<String, dynamic>? _userData;
  late TextEditingController _aboutController;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      _userData = doc.data();
      _aboutController = TextEditingController(text: _userData?['about'] ?? '');

      // Calculate and update profile completion
      int newCompletion = _calculateProfileCompletion(_userData!);

      if ((_userData?['profileCompletion'] ?? 0) != newCompletion) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profileCompletion': newCompletion,
        });
        _userData?['profileCompletion'] = newCompletion;
      }

      setState(() => _loading = false);
    }
  }

  int _calculateProfileCompletion(Map<String, dynamic> data) {
    int completed = 0;
    int totalFields = 7; // name, dob, gender, avatar, interests, disabilities, about

    if ((data['name'] ?? '').toString().isNotEmpty) completed++;
    if ((data['dob'] ?? '').toString().isNotEmpty) completed++;
    if ((data['gender'] ?? '').toString().isNotEmpty) completed++;
    if ((data['avatar'] ?? '').toString().isNotEmpty) completed++;
    if ((data['interests'] ?? []).isNotEmpty) completed++;
    if ((data['disabilities'] ?? []).isNotEmpty) completed++;
    if ((data['about'] ?? '').toString().isNotEmpty) completed++;

    return ((completed / totalFields) * 100).round();
  }

  Future<void> _updateAbout(String about) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userData?['about'] = about;
    int newCompletion = _calculateProfileCompletion(_userData!);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'about': about,
      'profileCompletion': newCompletion,
    });

    setState(() {
      _userData?['profileCompletion'] = newCompletion;
    });
  }

  @override
  void dispose() {
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = _userData?['name'] ?? '';
    final dob = _userData?['dob'] != null ? DateTime.parse(_userData!['dob']) : null;
    final gender = _userData?['gender'] ?? '';
    final avatarUrl = _userData?['avatar'] as String?;
    final interests = List<String>.from(_userData?['interests'] ?? []);
    final disabilities = List<String>.from(_userData?['disabilities'] ?? []);
    final about = _userData?['about'] ?? '';
    final profileCompletion = _userData?['profileCompletion'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            CircleAvatar(
              radius: 50,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : const AssetImage('assets/avatar.png') as ImageProvider,
            ),
            const SizedBox(height: 12),
            Text(
              "$name, ${dob != null ? DateTime.now().year - dob.year : '--'}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text("Bangkok, Thailand", style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: profileCompletion / 100,
                    backgroundColor: Colors.grey[300],
                    color: Colors.deepPurple,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$profileCompletion% Complete",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FBFF),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow("Name", name),
                  const SizedBox(height: 10),
                  _infoRow(
                      "Date of Birth",
                      dob != null
                          ? "${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}"
                          : ""),
                  const SizedBox(height: 10),
                  _infoRow("Gender", gender),
                  const SizedBox(height: 10),
                  _chipSection("Interests", interests),
                  const SizedBox(height: 10),
                  _chipSection("Disabilities", disabilities),
                  const SizedBox(height: 12),
                  const Text("About you", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _aboutController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: "Tell us more about yourself",
                    ),
                    onChanged: (val) => _updateAbout(val),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }

  Widget _chipSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: items.map((i) => Chip(label: Text(i))).toList()),
      ],
    );
  }
}
