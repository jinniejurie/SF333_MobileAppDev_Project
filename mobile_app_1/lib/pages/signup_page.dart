import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ลบ import firebase_storage เพราะไม่ใช้แล้ว
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
      print("Avatar conversion to Base64 failed: $e");
      return null;
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

      // 🔹 สร้าง user ใน Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      final uid = userCredential.user!.uid;

      // 🔹 แปลง avatar เป็น Base64 (ถ้ามี)
      String? avatarBase64;
      if (_avatar != null) {
        avatarBase64 = await _convertAvatarToBase64();
        if (avatarBase64 == null) {
          // ถ้าแปลงไม่สำเร็จ
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to convert avatar image, continuing without avatar")),
          );
        }
      }

      // 🔹 บันทึกข้อมูลเพิ่มใน Firestore
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "name": _name.text.trim(),
        "dob": _pickedDob!.toIso8601String(),
        "gender": _gender,
        "email": _email.text.trim(),
        "avatarBase64": avatarBase64, // เก็บ Base64 string หรือ null ถ้าไม่มีภาพ
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup successful!")),
      );

      // 🔹 ไปหน้า disability ต่อ
      Navigator.pushNamed(context, '/disability');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Signup failed")),
      );
    } finally {
      setState(() => _loading = false);
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
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) =>
                (v == null || v.length < 6) ? 'Min 6 chars' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Confirm password' : null,
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
