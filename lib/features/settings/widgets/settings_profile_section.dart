import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class SettingsProfileSection extends StatelessWidget {
  final String userName;
  final String userNik;

  const SettingsProfileSection({
    super.key,
    required this.userName,
    required this.userNik,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryColor,
              width: 2.5,
            ),
          ),
          child: const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFFE2E8F0),
            child: Icon(
              Icons.person,
              size: 55,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          userName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'NIK: $userNik',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}