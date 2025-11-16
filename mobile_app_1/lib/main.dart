// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:my_app/screens/splash_screen.dart';
import 'package:my_app/screens/welcome_page.dart';
import 'package:my_app/screens/swipe.dart'; // <-- your CardSwipe page
import 'package:my_app/screens/community_home.dart';
import 'package:my_app/screens/create_post_page.dart';
import 'package:my_app/screens/chat_list_screen.dart';
import 'package:my_app/screens/friends_screen.dart';
import 'package:my_app/screens/login_page.dart';
import 'package:my_app/screens/signup_page.dart';
import 'package:my_app/screens/disability_page.dart';
import 'package:my_app/screens/interests_page.dart';
import 'package:my_app/screens/final_profile_page.dart';
import 'package:my_app/screens/profile_settings_page.dart';
import 'package:my_app/providers/accessibility_provider.dart';
import 'package:my_app/services/tts_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    // Ensure there is a user for Firestore security rules
    await FirebaseAuth.instance.signInAnonymously();
  } catch (_) {}
  
  // TTS will be initialized lazily when needed
  // Don't initialize here to avoid platform channel errors
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AccessibilityProvider(),
      child: Consumer<AccessibilityProvider>(
        builder: (context, accessibility, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Discover People',
            theme: accessibility.getTheme(context),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: accessibility.fontScale,
                ),
                child: child!,
              );
            },
            routes: {
              '/': (context) => const SplashScreen(),
              '/welcome': (context) => const WelcomePage(),
              '/home': (context) => const CommunityHome(),
              '/swipe': (context) => const CardSwipe(),
              '/createPost': (context) => const CreatePostPage(),
              '/chatList': (context) => const ChatListScreen(),
              '/friendsScreen': (context) => const FriendsScreen(),
              '/communityDiscover': (context) => const CommunityDiscoverPage(),
              '/login': (context) => const LoginPage(),
              '/signup': (context) => const SignUpPage(),
              '/disability': (context) => const DisabilityPage(),
              '/interests': (context) => const InterestsPage(),
              '/final': (context) => const FinalProfilePage(),
              '/profileSettings': (context) => const ProfileSettingsPage(),
            },
            initialRoute: '/',
          );
        },
      ),
    );
  }
}
