import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'community_home.dart';
import 'disability_page.dart';
import 'interests_page.dart';
import 'final_profile_page.dart';
import '../widgets/base_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _hasCompletedProfile = false;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      setState(() => _isLoggedIn = true);
      
      // ตรวจสอบว่าผู้ใช้ได้กรอกข้อมูลโปรไฟล์ครบถ้วนหรือไม่
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          final hasBio = userData?['bio'] != null && userData!['bio'].toString().isNotEmpty;
          final hasInterests = userData?['interest'] != null && (userData!['interest'] as List).isNotEmpty;
          final hasDisabilities = userData?['disability'] != null && (userData!['disability'] as List).isNotEmpty;
          
          setState(() => _hasCompletedProfile = hasBio && hasInterests && hasDisabilities);
        }
      } catch (e) {
        debugPrint('Error checking profile completion: $e');
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ถ้าผู้ใช้ login แล้วและมีโปรไฟล์ครบถ้วน ให้ไปหน้า CommunityHome
    if (_isLoggedIn && _hasCompletedProfile) {
      return const CommunityHome();
    }

    // ถ้าผู้ใช้ login แล้วแต่ยังไม่มีโปรไฟล์ครบถ้วน ให้ไปหน้า Profile Setup
    if (_isLoggedIn && !_hasCompletedProfile) {
      return const ProfileSetupPage();
    }

    // ถ้ายังไม่ได้ login ให้แสดงหน้า Welcome
    return _buildWelcomeScreen();
  }

  Widget _buildWelcomeScreen() {
    return BasePage(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD6F0FF), Color(0xFFEFF4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/cloud_logo.png',
                  width: 120,
                  height: 100,
                ),
                const SizedBox(height: 40),
                
                // Title
                const Text(
                  'Welcome to OnCloud',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Subtitle
                const Text(
                  'Connect with people who share your interests and experiences',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
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

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final PageController _pageController = PageController();

  final List<Widget> _steps = [
    const SignUpPage(),
    const DisabilityPage(),
    const InterestsPage(),
    const FinalProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkCurrentStep();
  }

  Future<void> _checkCurrentStep() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final hasDisabilities = userData?['disability'] != null && (userData!['disability'] as List).isNotEmpty;
        final hasInterests = userData?['interest'] != null && (userData!['interest'] as List).isNotEmpty;
        final hasBio = userData?['bio'] != null && userData!['bio'].toString().isNotEmpty;

        if (hasDisabilities && hasInterests && hasBio) {
          // Profile is complete, go to main app
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CommunityHome()),
            );
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error checking profile status: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _steps,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
