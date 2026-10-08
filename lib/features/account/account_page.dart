import 'package:flutter/material.dart';

import '../../core/session/session_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_image.dart';
import '../../data/repository.dart';
import '../auth/login_page.dart';
import '../iot/iot_page.dart';
import '../notifications/b3_alerts_page.dart';
import 'change_password_page.dart';
import 'edit_profile_page.dart';
import 'help_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Map<String, String> _user = const {};
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = await SessionStore.user();
    if (mounted) setState(() => _user = u);
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    _loadUser();
  }

  Future<void> _logout() async {
    final ok = await AppFeedback.confirm(
      context,
      title: 'Keluar dari akun?',
      message: 'Timbangan IoT yang terhubung dengan akun ini juga akan diputus.',
      confirmLabel: 'Keluar',
      destructive: true,
    );
    if (!ok) return;
    setState(() => _loggingOut = true);
    try {
      await Repo.logout();
    } catch (_) {
      // Tetap keluar walau server tidak bisa dihubungi
    }
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final name = _user['full_name'] ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                child: UserAvatar(name: name, photo: _user['photo'], size: 60),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name.isEmpty ? 'PIC' : name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  Text('NIK ${_user['nik'] ?? '-'}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                  if ((_user['email'] ?? '').isNotEmpty)
                    Text(_user['email']!, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                ]),
              ),
              IconButton(
                tooltip: 'Edit profil',
                onPressed: () => _open(const EditProfilePage()),
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        _group('Akun', [
          _item(Icons.person_outline_rounded, 'Edit profil', () => _open(const EditProfilePage())),
          _item(Icons.lock_outline_rounded, 'Ubah kata sandi', () => _open(const ChangePasswordPage())),
        ]),
        const SizedBox(height: 16),
        _group('Operasional', [
          _item(Icons.scale_outlined, 'Timbangan IoT', () => _open(const IotPage())),
          _item(Icons.science_outlined, 'Peringatan limbah B3', () => _open(const B3AlertsPage())),
        ]),
        const SizedBox(height: 16),
        _group('Lainnya', [
          _item(Icons.help_outline_rounded, 'Pusat bantuan', () => _open(const HelpPage())),
        ]),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4))),
          onPressed: _loggingOut ? null : _logout,
          icon: _loggingOut
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.logout_rounded),
          label: const Text('Keluar'),
        ),
        const SizedBox(height: 16),
        const Center(child: Text('WasteTrack • Politeknik Negeri Batam', style: TextStyle(color: AppColors.muted, fontSize: 12))),
      ]),
    );
  }

  Widget _group(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.8)),
      ),
      Card(
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const Divider(indent: 56), children[i]],
        ]),
      ),
    ]);
  }

  Widget _item(IconData icon, String label, VoidCallback onTap) => ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.inkSoft),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      );
}
