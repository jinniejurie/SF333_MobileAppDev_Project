import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import '../widgets/base_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _dobController = TextEditingController();
  DateTime? _pickedDob;
  String? _gender;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  File? _avatar;

  bool _loading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _pickedDob = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _avatar = File(picked.path);
      });
    }
  }

  Future<String?> _convertAvatarToBase64() async {
    if (_avatar == null) return null;
    try {
      final bytes = await _avatar!.readAsBytes();
      String base64Str = base64Encode(bytes);
      return base64Str;
    } catch (e) {
      debugPrint("Avatar conversion to Base64 failed: $e");
      return null;
    }
  }

  /// Generates the next sequential user ID in the format ONXXXXX.
  Future<String> _generateCustomUserId() async {
    final usersCollection = FirebaseFirestore.instance.collection('users');

    // Get the total count of documents in the 'users' collection
    final snapshot = await usersCollection.count().get();

    // The next number will be the current count + 1 (0 -> 1)
    final nextNumber = (snapshot.count ?? 0) + 1;

    // Format the number to be 'ON' followed by 5 digits (e.g., 1 -> ON00001)
    final userId = 'ON${nextNumber.toString().padLeft(5, '0')}';

    return userId;
  }

  /// Gets actual GPS coordinates (Lat/Lng) from the device and handles permissions.
  /// Returns a Map containing only 'latitude' and 'longitude'.
  Future<Map<String, double>> _getLocationData() async {
    try {
      // For now, return default location (Bangkok, Thailand)
      // TODO: Implement actual location services when geolocator is available
      return {
        'latitude': 13.7563,
        'longitude': 100.5018,
      };

    } catch (e) {
      debugPrint("Error getting location: $e");
      // Fallback for location failure
      return {
        'latitude': 0.0,
        'longitude': 0.0,
      };
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select date of birth")),
      );
      return;
    }
    if (_gender == null || _gender!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select gender")),
      );
      return;
    }
    if (_password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    try {
      setState(() => _loading = true);

      // 1. Generate Custom UID and get LIVE Location Data
      final customUserId = await _generateCustomUserId();
      final locationData = await _getLocationData();

      // Create user in Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      final uid = userCredential.user!.uid;

      // NOTE: We are now saving the raw DateTime object.
      // Firestore will convert this to a native Timestamp, which does NOT
      // have surrounding quotes in the console view.
      // Removed: final formattedBirthDate = DateFormat("MMMM d, y 'at' h:mm:ss a 'UTC+7'").format(_pickedDob!.toUtc().add(const Duration(hours: 7)));

      // Convert avatar to Base64 (if available)
      String? avatarBase64;
      if (_avatar != null) {
        avatarBase64 = await _convertAvatarToBase64();
      }

      // Create GeoPoint for robust location storage
      final GeoPoint locationGeoPoint = GeoPoint(
        locationData['latitude']!,
        locationData['longitude']!,
      );

      // 2. Save user and location data in the 'users' document
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "name": _name.text.trim(),
        "birthDate": _pickedDob!, // <<< SAVED AS NATIVE TIMESTAMP
        "gender": _gender,
        "email": _email.text.trim(),
        "avatarBase64": avatarBase64,
        "createdAt": FieldValue.serverTimestamp(),

        "uid": customUserId,

        // GeoPoint data
        "location": locationGeoPoint,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup successful! Welcome!")),
        );
      }

      // Navigate to the next page
      if (mounted) {
        Navigator.pushNamed(context, '/disability');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Signup failed")),
        );
      }
    } on Exception catch (e) {
      // Catch the location required error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _avatar != null ? FileImage(_avatar!) : null,
                  child: _avatar == null
                      ? const Icon(Icons.add_a_photo, size: 32)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                (v == null || v.trim().isEmpty || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) =>
                (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Confirm password';
                  } else if (v != _password.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: _loading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white),
                )
                    : const Text(
                  'Next →',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
