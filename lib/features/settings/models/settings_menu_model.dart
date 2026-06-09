import 'package:flutter/material.dart';

class SettingsMenuModel {
  final IconData icon;
  final String title;
  final bool showBadge;
  final VoidCallback onTap;

  const SettingsMenuModel({
    required this.icon,
    required this.title,
    required this.onTap,
    this.showBadge = false,
  });
}