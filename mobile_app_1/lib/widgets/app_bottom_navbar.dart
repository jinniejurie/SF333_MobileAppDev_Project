/// Bottom navigation bar widget with accessibility support.
/// 
/// Provides navigation between main app sections with icons that adapt
/// to high contrast mode. Includes semantic labels for screen readers.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/community_discover_page.dart';
import '../screens/swipe.dart';
import '../providers/accessibility_provider.dart';

/// Bottom navigation bar for main app navigation.
/// 
/// Displays icons for Home, Explore, Create, Friends, and Chat.
/// Adapts colors based on accessibility settings.
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

  /// Gets the appropriate icon color based on selection and contrast mode.
  Color _getIconColor(int index, bool isHighContrast) {
    if (currentIndex == index) {
      return isHighContrast ? Colors.black : const Color(0xFF90CAF9);
    }
    return Colors.black54;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, accessibility, _) {
        final isHighContrast = accessibility.highContrastMode;
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isHighContrast ? Colors.white : Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isHighContrast
                ? [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20),
                  ]
                : const [
                    BoxShadow(color: Color(0xFFD6F0FF), blurRadius: 20),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                label: 'Home',
                button: true,
                child: IconButton(
                  onPressed: () => onChanged(0),
                  icon: Icon(Icons.home_rounded, color: _getIconColor(0, isHighContrast)),
                ),
              ),
              Semantics(
                label: 'Explore communities',
                button: true,
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CommunityDiscoverPage()),
                    );
                  },
                  icon: Icon(Icons.explore_outlined, color: _getIconColor(1, isHighContrast)),
                ),
              ),
              Semantics(
                label: 'Create new post',
                button: true,
                child: GestureDetector(
                  onTap: onPlus,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isHighContrast ? Colors.black : const Color(0xFF90CAF9),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ),
              Semantics(
                label: 'Friends',
                button: true,
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/swipe');
                  },
                  icon: Icon(Icons.group_outlined, color: _getIconColor(3, isHighContrast)),
                ),
              ),
              Semantics(
                label: 'Chat',
                button: true,
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/chatList');
                  },
                  icon: Stack(
                    children: [
                      Icon(Icons.chat_bubble_outline, color: _getIconColor(4, isHighContrast)),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isHighContrast ? Colors.black : Colors.blue,
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
              ),
            ],
          ),
        );
      },
    );
  }
}
