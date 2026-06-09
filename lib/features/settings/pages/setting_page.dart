import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/pages/login_page.dart';

import '../models/settings_menu_model.dart';

import '../widgets/settings_header.dart';
import '../widgets/settings_profile_section.dart';
import '../widgets/settings_menu_group.dart';
import '../widgets/logout_button.dart';

import 'edit_profile_page.dart';
import 'change_password_page.dart';
import 'notification_page.dart';
import 'help_center_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _userName = 'Memuat...';
  String _userNik = '-';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _userName = prefs.getString('user_name') ?? 'Nama Karyawan';
      _userNik = prefs.getString('user_nik') ?? '-';
    });
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Keluar Akun'),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();

                await prefs.clear();

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(),
                    ),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Keluar',
                style: TextStyle(
                  color: Color(0xFFE26B50),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<SettingsMenuModel> _buildMainMenus() {
    return [
      SettingsMenuModel(
        icon: Icons.person_outline,
        title: 'Pengaturan Profil',
        onTap: () async {
          final shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EditProfilePage(),
            ),
          );

          if (shouldRefresh == true) {
            _loadUserData();
          }
        },
      ),
      SettingsMenuModel(
        icon: Icons.key_outlined,
        title: 'Ganti Password',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PengaturanPasswordPage(),
            ),
          );
        },
      ),
      SettingsMenuModel(
        icon: Icons.notifications_none_outlined,
        title: 'Notifikasi',
        showBadge: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotifikasiPage(),
            ),
          );
        },
      ),
      SettingsMenuModel(
        icon: Icons.router_outlined,
        title: 'Integrasi IoT',
        onTap: () {
          // TODO:
        },
      ),
    ];
  }

  List<SettingsMenuModel> _buildSupportMenus() {
    return [
      SettingsMenuModel(
        icon: Icons.help_outline,
        title: 'Bantuan',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const HelpCenterPage(),
            ),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 115,
                color: AppTheme.primaryColor,
              ),
              const SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SettingsHeader(),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    SettingsProfileSection(
                      userName: _userName,
                      userNik: _userNik,
                    ),
                    const SizedBox(height: 30),
                    SettingsMenuGroup(
                      items: _buildMainMenus(),
                    ),
                    const SizedBox(height: 20),
                    SettingsMenuGroup(
                      items: _buildSupportMenus(),
                    ),
                    const SizedBox(height: 25),
                    LogoutButton(
                      onPressed: _logout,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}