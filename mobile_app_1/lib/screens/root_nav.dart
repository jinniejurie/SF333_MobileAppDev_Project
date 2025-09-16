import 'package:flutter/material.dart';
import 'event_list_page.dart';

class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _currentIndex = 1; // default to Discover

  late final List<Widget> _pages = <Widget>[
    const _HostPage(child: _PlaceholderPage(title: 'Home')),
    _HostPage(child: EventListPage()),
    const _HostPage(child: _PlaceholderPage(title: 'Add Event')),
    const _HostPage(child: _PlaceholderPage(title: 'Community')),
    const _HostPage(child: _PlaceholderPage(title: 'Messages')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      extendBody: true, // ให้ตัว body ลอดด้านหลัง nav bar เพื่อให้โปร่งใส
      body: _pages[_currentIndex],
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        child: _RoundedBottomBar(
          currentIndex: _currentIndex,
          onChanged: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            _BarItem(icon: Icons.home_filled),
            _BarItem(icon: Icons.explore),
            _BarItem(icon: Icons.add),
            _BarItem(icon: Icons.groups_rounded),
            _BarItem(icon: Icons.chat_bubble_outline),
          ],
        ),
      ),
    );
  }
}

class _RoundedBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<_BarItem> items;

  const _RoundedBottomBar({
    required this.currentIndex,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final Color pillColor = Colors.white.withOpacity(0.92);
    final Color iconColor = const Color(0xFF8D6FA6); // soft purple-gray
    final Color activeBg = const Color(0xFF3C1C4D); // deep purple
    final Color shadowColor = Colors.black.withOpacity(0.08);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (int index) {
          final bool isActive = index == currentIndex;
          final IconData icon = items[index].icon;

          return _NavButton(
            isActive: isActive,
            icon: icon,
            activeBg: activeBg,
            inactiveColor: iconColor,
            onTap: () => onChanged(index),
          );
        }),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final bool isActive;
  final IconData icon;
  final Color activeBg;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavButton({
    required this.isActive,
    required this.icon,
    required this.activeBg,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: activeBg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 24, color: Colors.white),
        ),
      );
    }
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: inactiveColor),
    );
  }
}

class _BarItem {
  final IconData icon;
  const _BarItem({required this.icon});
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: const TextStyle(fontSize: 22)),
    );
  }
}

class _HostPage extends StatelessWidget {
  final Widget child;
  const _HostPage({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: child,
    );
  }
}


