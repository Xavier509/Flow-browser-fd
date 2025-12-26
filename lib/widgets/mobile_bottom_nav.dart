import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../utils/constants.dart';

class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BrowserProvider>();
    final isBookmarked = provider.isBookmarked(provider.currentTab.url);

    return BottomNavigationBar(
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
      onTap: (index) {
        // Handle navigation
        if (index == 0) {
          provider.goHome();
        } else if (index == 1) {
          // Open settings - handled by parent
        }
      },
    );
  }
}