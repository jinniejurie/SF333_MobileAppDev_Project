import 'package:flutter/material.dart';
import '../screens/community_discover_page.dart';
import '../screens/swipe.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onPlus;
  
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.onPlus,
  });

  Color _color(int i) => currentIndex == i ? const Color(0xFF90CAF9) : Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Color(0xFFD6F0FF), blurRadius: 20),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => onChanged(0),
            icon: Icon(Icons.home_rounded, color: _color(0)),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CommunityDiscoverPage()),
              );
            },
            icon: Icon(Icons.explore_outlined, color: _color(1)),
          ),
          GestureDetector(
            onTap: onPlus,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF90CAF9),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/friendsScreen');
            },
            icon: Icon(Icons.group_outlined, color: _color(3)),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/chatList');
            },
            icon: Stack(
              children: [
                Icon(Icons.chat_bubble_outline, color: _color(4)),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
