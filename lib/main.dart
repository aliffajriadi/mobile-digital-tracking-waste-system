import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/pages/login_page.dart';

void main() {
  runApp(const WasteTrackApp());
}

class WasteTrackApp extends StatelessWidget {
  const WasteTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WasteTrack',
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
    );
  }
}