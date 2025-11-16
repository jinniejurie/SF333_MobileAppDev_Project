/// Detail page for viewing full user profile information from swipe cards.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../providers/accessibility_provider.dart';
import '../widgets/accessible_container.dart';

class SwipeDetailPage extends StatelessWidget {
  final String userId;
  final String name;
  final String gender;
  final String bio;
  final int age;
  final String? profileImageUrl;
  final Uint8List? profileImageBytes;
  final List<String> disabilities;
  final List<String> interests;
  final String distanceText;

  const SwipeDetailPage({
    super.key,
    required this.userId,
    required this.name,
    required this.gender,
    required this.bio,
    required this.age,
    this.profileImageUrl,
    this.profileImageBytes,
    required this.disabilities,
    required this.interests,
    required this.distanceText,
  });

  Widget _buildProfileImage() {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return Image.network(
        profileImageUrl!,
        width: double.infinity,
        height: 400,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Consumer<AccessibilityProvider>(
          builder: (context, accessibility, _) {
            return Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                color: accessibility.highContrastMode
                    ? Colors.white
                    : const Color(0xFFD6F0FF),
                borderRadius: BorderRadius.circular(20),
                border: accessibility.highContrastMode
                    ? Border.all(color: Colors.black, width: 2)
                    : null,
              ),
              child: Icon(
                Icons.person,
                size: 150,
                color: accessibility.highContrastMode
                    ? Colors.black
                    : const Color(0xFF90CAF9),
              ),
            );
          },
        ),
      );
    } else if (profileImageBytes != null) {
      return Image.memory(
        profileImageBytes!,
        width: double.infinity,
        height: 400,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Consumer<AccessibilityProvider>(
          builder: (context, accessibility, _) {
            return Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                color: accessibility.highContrastMode
                    ? Colors.white
                    : const Color(0xFFD6F0FF),
                borderRadius: BorderRadius.circular(20),
                border: accessibility.highContrastMode
                    ? Border.all(color: Colors.black, width: 2)
                    : null,
              ),
              child: Icon(
                Icons.person,
                size: 150,
                color: accessibility.highContrastMode
                    ? Colors.black
                    : const Color(0xFF90CAF9),
              ),
            );
          },
        ),
      );
    } else {
      return Consumer<AccessibilityProvider>(
        builder: (context, accessibility, _) {
          return Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              color: accessibility.highContrastMode
                  ? Colors.white
                  : const Color(0xFFD6F0FF),
              borderRadius: BorderRadius.circular(20),
              border: accessibility.highContrastMode
                  ? Border.all(color: Colors.black, width: 2)
                  : null,
            ),
            child: Icon(
              Icons.person,
              size: 150,
              color: accessibility.highContrastMode
                  ? Colors.black
                  : const Color(0xFF90CAF9),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AccessibleContainer(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD6F0FF), Color(0xFFEFF4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  child: _buildProfileImage(),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Age
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$name, $age',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Gender
                      if (gender.isNotEmpty)
                        Text(
                          gender,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // Distance
                      if (distanceText.isNotEmpty)
                        Text(
                          distanceText,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Bio
                      if (bio.isNotEmpty) ...[
                        Semantics(
                          header: true,
                          child: const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bio,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Disabilities
                      if (disabilities.isNotEmpty) ...[
                        Semantics(
                          header: true,
                          child: const Text(
                            'Disabilities',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Consumer<AccessibilityProvider>(
                          builder: (context, accessibility, _) {
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: disabilities.map((disability) {
                                return Chip(
                                  label: Text(
                                    disability,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  backgroundColor: accessibility.highContrastMode
                                      ? Colors.white
                                      : const Color(0xFFD6F0FF),
                                  shape: StadiumBorder(
                                    side: BorderSide(
                                      color: Colors.black,
                                      width: accessibility.highContrastMode ? 2 : 1,
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Interests
                      if (interests.isNotEmpty) ...[
                        Semantics(
                          header: true,
                          child: const Text(
                            'Interests',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: interests.map((interest) {
                            return Chip(
                              label: Text(
                                interest,
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.black,
                              shape: const StadiumBorder(
                                side: BorderSide(color: Colors.black, width: 1),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

