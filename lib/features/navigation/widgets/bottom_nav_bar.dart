import 'package:flutter/material.dart';
import '../models/nav_item_model.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavItemModel> items;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: primaryColor,
      unselectedItemColor: const Color(0xFF94A3B8),
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onTap: onTap,
      items: items
          .map(
            (e) => BottomNavigationBarItem(
              icon: Icon(e.icon),
              label: e.label,
            ),
          )
          .toList(),
    );
  }
}