import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/form_widgets.dart';
import '../../data/repository.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _showOld = false;
  bool _showNew = false;
  bool _saving = false;
  ApiException? _serverError;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final message = await Repo.changePassword(_old.text, _new.text);
      if (!mounted) return;
      AppFeedback.success(context, message);
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _serverError = e);
      if (!e.isValidation) AppFeedback.snack(context, e.message, type: FeedbackType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = _new.text.length >= 12 ? 3 : (_new.text.length >= 8 ? 2 : (_new.text.isEmpty ? 0 : 1));
    final strengthColor = [AppColors.line, AppColors.danger, AppColors.warning, AppColors.success][strength];

    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Kata Sandi')),
      bottomNavigationBar: BottomActionBar(label: 'Simpan Kata Sandi', loading: _saving, onPressed: _save),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Setelah diganti, akun Anda di perangkat lain akan otomatis keluar.', style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
          const SizedBox(height: 20),
          const FieldLabel('Kata sandi saat ini'),
          TextFormField(
            controller: _old,
            obscureText: !_showOld,
            validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
            decoration: InputDecoration(
              errorText: _serverError?.fieldError('old_password'),
              suffixIcon: IconButton(
                tooltip: _showOld ? 'Sembunyikan' : 'Tampilkan',
                icon: Icon(_showOld ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _showOld = !_showOld),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const FieldLabel('Kata sandi baru'),
          TextFormField(
            controller: _new,
            obscureText: !_showNew,
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (v == null || v.length < 8) return 'Minimal 8 karakter';
              if (v == _old.text) return 'Harus berbeda dari kata sandi saat ini';
              return null;
            },
            decoration: InputDecoration(
              errorText: _serverError?.fieldError('new_password'),
              suffixIcon: IconButton(
                tooltip: _showNew ? 'Sembunyikan' : 'Tampilkan',
                icon: Icon(_showNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _showNew = !_showNew),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            for (var i = 1; i <= 3; i++)
              Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(color: i <= strength ? strengthColor : AppColors.line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
          ]),
          const SizedBox(height: 4),
          Text(['', 'Terlalu pendek', 'Cukup', 'Kuat'][strength], style: TextStyle(fontSize: 12, color: strengthColor)),
          const SizedBox(height: 16),
          const FieldLabel('Ulangi kata sandi baru'),
          TextFormField(
            controller: _confirm,
            obscureText: !_showNew,
            validator: (v) => v != _new.text ? 'Kata sandi tidak sama' : null,
          ),
        ]),
      ),
    );
  }
}
