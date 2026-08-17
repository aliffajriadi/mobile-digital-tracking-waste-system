import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class SettingsProfileSection extends StatelessWidget {
  final String userName;
  final String userNik;
  final String? userPhoto;

  const SettingsProfileSection({
    super.key,
    required this.userName,
    required this.userNik,
    this.userPhoto,
  });

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF14A38B),
      const Color(0xFFE26B50),
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED),
      const Color(0xFFDB2777),
      const Color(0xFF059669),
      const Color(0xFFD97706),
    ];
    if (name.isEmpty) return colors[0];
    final hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    return colors[hash % colors.length];
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

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
          child: CircleAvatar(
            radius: 50,
            backgroundColor: _getAvatarColor(userName),
            child: Text(
              _getInitials(userName),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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