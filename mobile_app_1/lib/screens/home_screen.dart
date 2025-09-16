import 'package:flutter/material.dart';

import 'chat_list_screen.dart';
import 'friends_screen.dart';
import 'requests_screen.dart';
import 'swipe.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 2; // default to Chat

  @override
  Widget build(BuildContext context) {
    final pages = [
      const CardSwipe(),
      FriendsScreen(),
      const ChatListScreen(),
      RequestsScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[_index],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: NavigationBar(
            height: 64,
            backgroundColor: Colors.transparent,
            indicatorColor: Colors.transparent,
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), label: ''),
              NavigationDestination(icon: Icon(Icons.add_circle_outline), label: ''),
              NavigationDestination(icon: Icon(Icons.group_outlined), label: ''),
              NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: ''),
            ],
          ),
        ),
      ),
    );
  }
}


