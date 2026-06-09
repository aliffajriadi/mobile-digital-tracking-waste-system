import 'package:flutter/material.dart';
import '../models/settings_menu_model.dart';
import 'settings_menu_tile.dart';

class SettingsMenuGroup extends StatelessWidget {
  final List<SettingsMenuModel> items;

  const SettingsMenuGroup({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Column(
            children: [
              SettingsMenuTile(item: item),
              if (index != items.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 68,
                  endIndent: 20,
                  color: Color(0xFFF1F5F9),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}