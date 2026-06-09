import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(
        top: 25,
        left: 8,
        right: 24,
        bottom: 20,
      ),
      child: Row(
        children: [
          Icon(
            Icons.settings,
            color: Colors.white,
            size: 28,
          ),
          SizedBox(width: 12),
          Text(
            'Pengaturan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}