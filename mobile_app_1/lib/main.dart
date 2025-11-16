/// Main entry point for the OnCloud application.
/// 
/// This app provides a social platform for people with disabilities to connect,
/// share experiences, and discover communities. It includes accessibility features
/// such as high contrast mode, text-to-speech, and dynamic font scaling.
library;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/accessibility_provider.dart';

// Screen imports
import 'screens/splash_screen.dart';
import 'screens/welcome_page.dart';
import 'screens/swipe.dart';
import 'screens/community_home.dart';
import 'screens/create_post_page.dart';
import 'screens/chat_list_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/disability_page.dart';
import 'screens/interests_page.dart';
import 'screens/final_profile_page.dart';
import 'screens/profile_settings_page.dart';

/// Application entry point.
/// 
/// Initializes Firebase and sets up anonymous authentication for Firestore
/// security rules. TTS service is initialized lazily when needed.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Sign in anonymously to satisfy Firestore security rules
  // This allows the app to access Firestore even when user is not logged in
  try {
    await FirebaseAuth.instance.signInAnonymously();
  } catch (_) {
    // Ignore errors - app can still work without anonymous auth
  }
  
  runApp(const MyApp());
}

/// Root widget of the application.
/// 
/// Sets up the MaterialApp with accessibility features, theme management,
/// and route configuration. Uses Provider for state management.
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
            title: 'OnCloud',
            theme: accessibility.getTheme(context),
            
            // Apply dynamic font scaling based on accessibility settings
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: accessibility.fontScale,
                ),
                child: child!,
              );
            },
            
            // Route configuration
            routes: _buildRoutes(),
            initialRoute: '/',
          );
        },
      ),
    );
  }

  /// Builds the route map for navigation.
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
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
    };
  }
}
