import 'package:flutter/material.dart';

import '../account/account_page.dart';
import '../history/history_page.dart';
import '../home/dashboard_page.dart';
import '../record/record_menu.dart';
import '../stock/stock_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // Indeks 2 pada NavigationBar adalah tombol "Catat" (membuka menu, bukan tab)
  static const _recordSlot = 2;

  void _onSelect(int i) {
    if (i == _recordSlot) {
      showRecordMenu(context);
      return;
    }
    setState(() => _index = i > _recordSlot ? i - 1 : i);
  }

  void goToTab(int tab) => setState(() => _index = tab);

  @override
  Widget build(BuildContext context) {
    final selected = _index >= _recordSlot ? _index + 1 : _index;
    return Scaffold(
      body: IndexedStack(index: _index, children: [
        DashboardPage(onOpenStock: () => goToTab(1), onOpenHistory: () => goToTab(2)),
        const StockPage(),
        const HistoryPage(),
        const AccountPage(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: _onSelect,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Beranda'),
          const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_rounded), label: 'Stok'),
          NavigationDestination(
            icon: Container(
              width: 52,
              height: 36,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
            label: 'Catat',
          ),
          const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Riwayat'),
          const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Akun'),
        ],
      ),
    );
  }
}
