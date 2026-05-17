// lib/widgets/app_bottom_nav.dart
// Android bottom navigation bar
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded, size: 22), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded, size: 22), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded, size: 28), label: 'New Job'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded, size: 22), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_rounded, size: 22), label: 'More'),
        ],
      ),
    );
  }
}
