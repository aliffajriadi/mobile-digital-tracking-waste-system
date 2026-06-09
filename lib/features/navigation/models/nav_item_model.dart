import 'package:flutter/material.dart';

class NavItemModel {
  final Widget page;
  final IconData icon;
  final String label;

  const NavItemModel({
    required this.page,
    required this.icon,
    required this.label,
  });
}