import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF87CEFA), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔹 โลโก้ใหญ่ด้านบน
              Padding(
                padding: const EdgeInsets.only(top: 50, bottom: 30),
                child: Center(
                  child: Image.asset(
                    "assets/logo.png", // ใส่ไฟล์โลโก้ใน assets
                    height: 150,
                  ),
                ),
              ),

              const Text(
                "Signup to Continue",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),

              // ปุ่ม Signup
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/signup");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: const Text("Sign Up"),
              ),
              const SizedBox(height: 20),

              // ปุ่ม Login
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/login");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: const Text("Login"),
              ),

              const SizedBox(height: 30),

              // 🔹 ปุ่ม Logout (ถ้ามี user login อยู่แล้ว)
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Logged out")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text("Logout"),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
