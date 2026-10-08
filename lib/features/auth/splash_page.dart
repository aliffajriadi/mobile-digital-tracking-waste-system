import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/session/session_store.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repository.dart';
import '../shell/main_shell.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Tampilkan logo sebentar saja, sambil memvalidasi token ke server
    final minDelay = Future.delayed(const Duration(milliseconds: 700));
    final token = await SessionStore.token();
    var loggedIn = token != null;

    if (loggedIn) {
      try {
        final user = await Repo.me();
        await SessionStore.saveUser(user);
      } on ApiException catch (e) {
        // 401 = token tidak berlaku lagi. Error jaringan: tetap masuk (mode tanpa koneksi).
        if (e.isUnauthorized) loggedIn = false;
      }
    }

    await minDelay;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, _, _) => loggedIn ? const MainShell() : const LoginPage(),
      transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 112,
            height: 112,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: ClipOval(child: Image.asset('lib/images/logo.png', fit: BoxFit.contain)),
          ),
          const SizedBox(height: 20),
          const Text('WasteTrack', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
          const SizedBox(height: 6),
          const Text('Sistem Monitoring Rumah Sampah', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 36),
          const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
        ]),
      ),
    );
  }
}
