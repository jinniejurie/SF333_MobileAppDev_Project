import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:geocoding/geocoding.dart'; // <--- Used for reverse geocoding
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class FinalProfilePage extends StatefulWidget {
  const FinalProfilePage({super.key});

  @override
  State<FinalProfilePage> createState() => _FinalProfilePageState();
}

class _FinalProfilePageState extends State<FinalProfilePage> {
  bool _loading = true;
  Map<String, dynamic>? _userData;
  late TextEditingController _bioController;
  // This will now strictly hold the City, Country string fetched from Firestore
  String _location = 'Location not set';
  String _customUserId = ''; // To store the ONXXXXX ID
  String? _newAvatarPath;

  // Added this to store the parsed birthDate object
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Helper method to resolve DocumentReference to name string
  Future<List<String>> _getNamesFromReferences(List<dynamic>? references) async {
    if (references == null || references.isEmpty) return [];

    List<String> names = [];
    for (var ref in references) {
      try {
        DocumentReference docRef;
        if (ref is DocumentReference) {
          docRef = ref;
        } else if (ref is String) {
          docRef = FirebaseFirestore.instance.doc(ref);
        } else {
          debugPrint('⚠️ Skipped invalid reference type: ${ref.runtimeType}');
          continue;
        }

        final doc = await docRef.get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          final name = data?['name'] as String?;
          if (name != null) {
            names.add(name);
          }
        }
      } catch (e) {
        debugPrint('❌ Error reading document: $e');
      }
    }
    return names;
  }

  // --- START OF FIXES ---
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return;

      _userData = userDoc.data();

      // FIX 1: Fetch the Custom User ID from the 'uid' field, as set in signup_page.dart
      _customUserId = _userData?['uid'] ?? 'N/A';

      // FIX 2: Handle birthDate as a native Firestore Timestamp
      final rawBirthDate = _userData?['birthDate'];
      if (rawBirthDate is Timestamp) {
        _birthDate = rawBirthDate.toDate();
      }

      // FIX 3: Get location string from GeoPoint
      final GeoPoint? geoPoint = _userData?['location'];
      if (geoPoint != null) {
        try {
          // For now, use a simple location display
          // TODO: Implement reverse geocoding when geocoding package is available
          _location = 'Lat: ${geoPoint.latitude.toStringAsFixed(2)}, Lon: ${geoPoint.longitude.toStringAsFixed(2)}';
        } catch (e) {
          debugPrint('❌ Location processing failed: $e');
          _location = 'Lat: ${geoPoint.latitude.toStringAsFixed(2)}, Lon: ${geoPoint.longitude.toStringAsFixed(2)}';
        }
      } else {
        _location = 'Location not set';
      }

      if (_userData?['avatarBase64'] != null) {
        _userData!['avatar'] = _userData!['avatarBase64'];
      }

      _bioController = TextEditingController(text: _userData?['bio'] ?? '');

      // Load interests and disabilities from document references
      _userData!['interest'] =
      await _getNamesFromReferences(_userData?['interest'] as List<dynamic>?);

      _userData!['disability'] =
      await _getNamesFromReferences(_userData?['disability'] as List<dynamic>?);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading profile: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
  // --- END OF FIXES ---

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

    // Check if the bio text is empty and provide a message if so
    if (_bioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bio cannot be empty.")),
      );
      return;
    }

    Map<String, dynamic> updatedData = {
      'bio': _bioController.text.trim(),
    };

    if (_newAvatarPath != null) {
      String? newAvatarBase64;
      try {
        final bytes = await File(_newAvatarPath!).readAsBytes();
        newAvatarBase64 = base64Encode(bytes);
        updatedData['avatarBase64'] = newAvatarBase64;
      } catch (e) {
        debugPrint("Failed to encode new avatar: $e");
        // If encoding fails, don't update the avatar field in Firestore
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updatedData);

      setState(() {
        // Update local state with new bio and possibly new avatar data
        _userData?['bio'] = updatedData['bio'];
        if (updatedData.containsKey('avatarBase64')) {
          _userData?['avatarBase64'] = updatedData['avatarBase64'];
        }
        _newAvatarPath = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile saved successfully")),
        );
        // Navigate to home after saving
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving profile: $e")),
        );
      }
    }
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
    // Use the stored and parsed _birthDate
    final DateTime? birthDate = _birthDate;


    final gender = _userData?['gender'] ?? '';
    final avatarData = _userData?['avatarBase64'] as String?;
    final interest = List<String>.from(_userData?['interest'] ?? []);
    final disability = List<String>.from(_userData?['disability'] ?? []);

    ImageProvider? avatarImage;
    if (_newAvatarPath != null) {
      // Use the newly picked image if available
      avatarImage = FileImage(File(_newAvatarPath!));
    } else if (avatarData != null) {
      try {
        // Use the saved base64 image
        avatarImage = MemoryImage(base64Decode(avatarData));
      } catch (_) {
        // Handle decoding failure
      }
    }

    // Format BirthDate for display as "31/12/2005"
    // Use the parsed _birthDate here
    final String displayBirthDate = birthDate != null ? DateFormat('dd/MM/yyyy').format(birthDate) : '--/--/----';


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
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? const Icon(Icons.add_a_photo, size: 32)
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            const Text("Tap image to change",
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            // Display Custom User ID (ONXXXXX)
            Text(
              "ID: $_customUserId",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            // Display the location in the requested "city, country" format
            Text(
              _location,
              style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFF7FBFF),
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow("Name", name),
                  const SizedBox(height: 10),
                  _infoRow(
                    "Date of Birth",
                    displayBirthDate,
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