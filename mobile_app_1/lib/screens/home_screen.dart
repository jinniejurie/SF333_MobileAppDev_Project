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
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.group_outlined), label: 'Friends'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.inbox_outlined), label: 'Requests'),
        ],
      ),
    );
  }
}


