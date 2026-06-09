import 'package:flutter/material.dart';

import '../../dashboard/pages/dashboard_page.dart';
import '../../settings/pages/setting_page.dart';
import '../../waste_data/pages/waste_list_page.dart';
import '../../history/pages/history_page.dart';

import '../models/nav_item_model.dart';
import '../widgets/bottom_nav_bar.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<NavItemModel> _navItems = [
    NavItemModel(
      page: const DashboardPage(),
      icon: Icons.home_filled,
      label: 'Beranda',
    ),
    NavItemModel(
      page: const LaporanDataHarianPage(),
      icon: Icons.delete_outline,
      label: 'Data Sampah',
    ),
    NavItemModel(
      page: const RiwayatPage(),
      icon: Icons.bar_chart_outlined,
      label: 'Riwayat',
    ),
    NavItemModel(
      page: const SettingsPage(),
      icon: Icons.person_outline,
      label: 'Pengaturan',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _navItems[_currentIndex].page,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}