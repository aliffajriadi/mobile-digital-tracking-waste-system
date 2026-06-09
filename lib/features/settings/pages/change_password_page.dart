import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/password_service.dart';
import '../widgets/password_input_field.dart';

class PengaturanPasswordPage extends StatefulWidget {
  const PengaturanPasswordPage({super.key});

  @override
  State<PengaturanPasswordPage> createState() => _PengaturanPasswordPageState();
}

class _PengaturanPasswordPageState extends State<PengaturanPasswordPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordService = PasswordService();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _oldPasswordController.addListener(() => setState(() {}));
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  void _changePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Semua kolom wajib diisi!', backgroundColor: Colors.redAccent);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('Kata sandi baru minimal harus 6 karakter!', backgroundColor: Colors.redAccent);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('Konfirmasi sandi baru tidak cocok!', backgroundColor: Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _passwordService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      final responseData = jsonDecode(response.body);

      setState(() => _isLoading = false);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _showSnackBar('Kata sandi berhasil diubah!', backgroundColor: Colors.green);
        
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        
        if (mounted) Navigator.pop(context);
      } else {
        final errorMsg = response.statusCode == 401
            ? 'Sesi habis, silakan login kembali.'
            : (responseData['message'] ?? 'Gagal mengubah kata sandi');
            
        _showSnackBar(errorMsg, backgroundColor: Colors.redAccent);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Terjadi kesalahan koneksi jaringan.', backgroundColor: Colors.redAccent);
    }
  }

  void _showSnackBar(String message, {required Color backgroundColor}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pengaturan Keamanan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 10, width: double.infinity, color: primaryColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- HEADER INFORMASI BARU ---
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2F9F3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: primaryColor,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Ubah Kata Sandi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Demi keamanan akun Anda, pastikan kata sandi baru sulit ditebak dan tidak digunakan untuk layanan lain.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- FORM INPUT UTAMA ---
                    PasswordInputField(
                      label: 'KATA SANDI LAMA',
                      controller: _oldPasswordController,
                      obscureText: _obscureOld,
                      hasValue: _oldPasswordController.text.isNotEmpty,
                      onToggleVisibility: () =>
                          setState(() => _obscureOld = !_obscureOld),
                    ),
                    const SizedBox(height: 20),
                    PasswordInputField(
                      label: 'KATA SANDI BARU',
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      hasValue: _newPasswordController.text.isNotEmpty,
                      onToggleVisibility: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    const SizedBox(height: 20),
                    PasswordInputField(
                      label: 'KONFIRMASI SANDI BARU',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      hasValue: _confirmPasswordController.text.isNotEmpty,
                      onToggleVisibility: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    const SizedBox(height: 32),
                    
                    // --- TOMBOL SIMPAN ---
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}