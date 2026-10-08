import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_exception.dart';
import '../../core/session/session_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/form_widgets.dart';
import '../../data/repository.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String _nik = '';
  String? _photoUrl;
  File? _newPhoto;
  bool _saving = false;
  bool _dirty = false;
  ApiException? _serverError;

  @override
  void initState() {
    super.initState();
    SessionStore.user().then((u) {
      if (!mounted) return;
      setState(() {
        _name.text = u['full_name'] ?? '';
        _email.text = u['email'] ?? '';
        _phone.text = u['phone'] ?? '';
        _nik = u['nik'] ?? '';
        _photoUrl = u['photo'];
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 800);
      if (picked != null) {
        setState(() {
          _newPhoto = File(picked.path);
          _dirty = true;
        });
      }
    } catch (_) {
      if (mounted) AppFeedback.snack(context, 'Tidak dapat membuka galeri.', type: FeedbackType.error);
    }
  }

  Future<void> _save() async {
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = await Repo.updateProfile(name: _name.text.trim(), email: _email.text.trim(), phone: _phone.text.trim(), photo: _newPhoto);
      await SessionStore.saveUser(user);
      if (!mounted) return;
      AppFeedback.success(context, 'Profil berhasil diperbarui.');
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
    return UnsavedChangesGuard(
      hasChanges: _dirty && !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Profil')),
        bottomNavigationBar: BottomActionBar(label: 'Simpan Profil', loading: _saving, onPressed: _save),
        body: Form(
          key: _formKey,
          onChanged: () => _dirty = true,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                    child: _newPhoto != null
                        ? ClipOval(child: Image.file(_newPhoto!, width: 96, height: 96, fit: BoxFit.cover))
                        : UserAvatar(name: _name.text, photo: _photoUrl, size: 96),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('Ketuk foto untuk mengganti', style: TextStyle(fontSize: 12, color: AppColors.inkSoft))),
            const SizedBox(height: 24),
            const FieldLabel('NIK'),
            TextFormField(
              key: ValueKey(_nik),
              initialValue: _nik,
              enabled: false,
              decoration: const InputDecoration(helperText: 'NIK hanya dapat diubah oleh admin.'),
            ),
            const SizedBox(height: 16),
            const FieldLabel('Nama lengkap'),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              decoration: InputDecoration(errorText: _serverError?.fieldError('name')),
            ),
            const SizedBox(height: 16),
            const FieldLabel('Email'),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Format email tidak valid';
                return null;
              },
              decoration: InputDecoration(errorText: _serverError?.fieldError('email')),
            ),
            const SizedBox(height: 16),
            const FieldLabel('No. HP', optional: true),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(hintText: '08xxxxxxxxxx', errorText: _serverError?.fieldError('phone')),
            ),
          ]),
        ),
      ),
    );
  }
}
