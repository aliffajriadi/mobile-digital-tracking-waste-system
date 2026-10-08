import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/network/api_exception.dart';
import '../../core/session/session_store.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repository.dart';
import '../shell/main_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nik = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nik.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Repo.login(_nik.text.trim(), _password.text);
      await SessionStore.saveLogin(res['token'].toString(), Map<String, dynamic>.from(res['user'] ?? {}));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(children: [
                Container(
                  width: double.infinity,
                  color: AppColors.primary,
                  padding: EdgeInsets.fromLTRB(28, MediaQuery.of(context).padding.top + 48, 28, 60),
                  child: Column(children: [
                    Container(
                      width: 84,
                      height: 84,
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: ClipOval(child: Image.asset('lib/images/logo.png', fit: BoxFit.contain)),
                    ),
                    const SizedBox(height: 18),
                    const Text('WasteTrack', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('Masuk untuk mulai mencatat sampah', style: TextStyle(color: Colors.white70)),
                  ]),
                ),
                Container(
                  width: double.infinity,
                  transform: Matrix4.translationValues(0, -28, 0),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Masuk Akun PIC', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text('Gunakan NIK dan kata sandi dari admin.', style: TextStyle(color: AppColors.inkSoft)),
                        const SizedBox(height: 24),
                        if (_error != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                              const SizedBox(width: 10),
                              Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                            ]),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _nik,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'NIK wajib diisi' : null,
                          decoration: const InputDecoration(labelText: 'NIK', prefixIcon: Icon(Icons.badge_outlined)),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          focusNode: _passwordFocus,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          validator: (v) => (v == null || v.isEmpty) ? 'Kata sandi wajib diisi' : null,
                          decoration: InputDecoration(
                            labelText: 'Kata sandi',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: _obscure ? 'Tampilkan' : 'Sembunyikan',
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                              : const Text('Masuk'),
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text('Lupa kata sandi? Hubungi admin untuk reset.', style: TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                        ),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }
}
