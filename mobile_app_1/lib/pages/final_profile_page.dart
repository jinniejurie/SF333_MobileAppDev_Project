import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

class FinalProfilePage extends StatefulWidget {
  const FinalProfilePage({super.key});

  @override
  State<FinalProfilePage> createState() => _FinalProfilePageState();
}

class _FinalProfilePageState extends State<FinalProfilePage> {
  bool _loading = true;
  Map<String, dynamic>? _userData;
  late TextEditingController _bioController;
  String _location = '';
  String? _newAvatarPath;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists) return;

      _userData = doc.data();
      _bioController = TextEditingController(text: _userData?['bio'] ?? '');

      // แปลงพิกัดเป็น location
      if (_userData?['latitude'] != null && _userData?['longitude'] != null) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            _userData!['latitude'],
            _userData!['longitude'],
          );
          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            _location =
            "${placemark.locality ?? placemark.subAdministrativeArea ?? ''}, ${placemark.country ?? ''}";
          }
        } catch (_) {
          _location = "Unknown location";
        }
      }

      // แปลง interest จาก DocumentReference เป็น List<String>
      if (_userData?['interest'] != null) {
        List<dynamic> refs = _userData!['interest'];
        List<String> interestNames = [];
        for (var ref in refs) {
          if (ref is DocumentReference) {
            final d = await ref.get();
            if (d.exists) {
              final data = d.data() as Map<String, dynamic>?; // cast
              if (data != null && data['name'] != null) {
                interestNames.add(data['name'] as String);
              }
            }
          } else if (ref is String) {
            interestNames.add(ref);
          }
        }
        _userData!['interest'] = interestNames;
      }

      // disability
      _userData!['disability'] = List<String>.from(_userData?['disability'] ?? []);

      // คำนวณ profile completion
      int newCompletion = _calculateProfileCompletion(_userData!);
      if ((_userData?['profileCompletion'] ?? 0) != newCompletion) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profileCompletion': newCompletion});
        _userData?['profileCompletion'] = newCompletion;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading profile: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  int _calculateProfileCompletion(Map<String, dynamic> data) {
    int completed = 0;
    int totalFields = 8; // name, dob, gender, avatar, interest, disability, bio, location

    if ((data['name'] ?? '').toString().isNotEmpty) completed++;
    if ((data['dob'] ?? '').toString().isNotEmpty) completed++;
    if ((data['gender'] ?? '').toString().isNotEmpty) completed++;
    if ((data['avatar'] ?? '').toString().isNotEmpty) completed++;
    if ((data['interest'] ?? []).isNotEmpty) completed++;
    if ((data['disability'] ?? []).isNotEmpty) completed++;
    if ((data['bio'] ?? '').toString().isNotEmpty) completed++;
    if (_location.isNotEmpty) completed++;

    return ((completed / totalFields) * 100).round();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _newAvatarPath = picked.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Map<String, dynamic> updatedData = {
      'bio': _bioController.text.trim(),
    };

    if (_newAvatarPath != null) {
      updatedData['avatar'] = _newAvatarPath;
    }

    int newCompletion = _calculateProfileCompletion({...?_userData, ...updatedData});
    updatedData['profileCompletion'] = newCompletion;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update(updatedData);

    setState(() {
      _userData = {...?_userData, ...updatedData};
      _newAvatarPath = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile saved successfully")),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
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
    final dob = _userData?['dob'] != null
        ? DateTime.parse(_userData!['dob'])
        : null;
    final gender = _userData?['gender'] ?? '';
    final avatarUrl = _newAvatarPath ?? _userData?['avatar'] as String?;
    final interest = List<String>.from(_userData?['interest'] ?? []);
    final disability = List<String>.from(_userData?['disability'] ?? []);
    final bio = _bioController.text;
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
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: avatarUrl != null
                    ? (avatarUrl.startsWith("http")
                    ? NetworkImage(avatarUrl)
                    : FileImage(File(avatarUrl)) as ImageProvider)
                    : const AssetImage('assets/avatar.png'),
              ),
            ),
            const SizedBox(height: 6),
            const Text("Tap image to change",
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            Text(
              "$name, ${dob != null ? DateTime.now().year - dob.year : '--'}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _location.isNotEmpty ? _location : "Bangkok, Thailand",
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
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
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
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
                        : "",
                  ),
                  const SizedBox(height: 10),
                  _infoRow("Gender", gender),
                  const SizedBox(height: 10),
                  _chipSection("Interest", interest),
                  const SizedBox(height: 10),
                  _chipSection("Disability", disability),
                  const SizedBox(height: 12),
                  const Text("Bio", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _bioController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      hintText: "Write something about yourself",
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Save Profile",
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
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
      decoration:
      BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((i) => Chip(label: Text(i))).toList(),
        ),
      ],
    );
  }
}
