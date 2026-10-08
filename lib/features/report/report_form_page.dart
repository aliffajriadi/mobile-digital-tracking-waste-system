import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/form_widgets.dart';
import '../../core/widgets/option_sheet.dart';
import '../../data/models.dart';
import '../../data/repository.dart';

class ReportFormPage extends StatefulWidget {
  const ReportFormPage({super.key});

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();

  List<NamedItem> _categories = [];
  bool _loadingCategories = true;
  NamedItem? _category;
  File? _attachment;
  bool _submitting = false;
  bool _submitted = false;

  bool get _dirty => _category != null || _title.text.isNotEmpty || _content.text.isNotEmpty || _attachment != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final list = await Repo.reportCategories();
      if (mounted) setState(() => _categories = list);
    } on ApiException catch (e) {
      if (mounted) AppFeedback.snack(context, e.message, type: FeedbackType.error);
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _pickCategory() async {
    if (_categories.isEmpty) {
      await _loadCategories();
      if (_categories.isEmpty) return;
    }
    if (!mounted) return;
    final picked = await showOptionSheet<NamedItem>(
      context,
      title: 'Kategori kendala',
      selected: _category,
      options: _categories.map((c) => SheetOption(value: c, title: c.name)).toList(),
    );
    if (picked != null) setState(() => _category = picked);
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate() || _category == null) {
      AppFeedback.snack(context, 'Lengkapi isian yang ditandai merah.', type: FeedbackType.error);
      return;
    }
    setState(() => _submitting = true);
    try {
      final message = await Repo.submitReport(
        categoryId: _category!.id,
        title: _title.text.trim(),
        content: _content.text.trim(),
        attachment: _attachment,
      );
      if (mounted) Navigator.of(context).pop(message);
    } on ApiException catch (e) {
      // Matikan loading dulu agar tombol tidak berputar di belakang dialog error
      if (mounted) setState(() => _submitting = false);
      if (mounted) await AppFeedback.error(context, e, title: 'Gagal mengirim');
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppFeedback.snack(context, 'Terjadi kesalahan tak terduga. Silakan coba lagi.', type: FeedbackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      hasChanges: _dirty && !_submitting,
      child: Scaffold(
        appBar: AppBar(title: const Text('Laporan Kendala')),
        bottomNavigationBar: BottomActionBar(label: 'Kirim Laporan', icon: Icons.send_rounded, loading: _submitting, onPressed: _submit),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.kendala.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14)),
              child: const Row(children: [
                Icon(Icons.support_agent_rounded, color: AppColors.kendala),
                SizedBox(width: 10),
                Expanded(child: Text('Laporan langsung diterima admin di panel web. Jelaskan masalah sedetail mungkin.', style: TextStyle(fontSize: 13, height: 1.4))),
              ]),
            ),
            const SizedBox(height: 20),
            const FieldLabel('Kategori'),
            PickerField(
              value: _category?.name,
              placeholder: 'Pilih kategori kendala',
              icon: Icons.category_outlined,
              loading: _loadingCategories,
              onTap: _pickCategory,
              errorText: _submitted && _category == null ? 'Kategori wajib dipilih' : null,
            ),
            const SizedBox(height: 20),
            const FieldLabel('Judul'),
            TextFormField(
              controller: _title,
              maxLength: 255,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
              decoration: const InputDecoration(hintText: 'Misal: Timbangan tidak menyala'),
            ),
            const SizedBox(height: 12),
            const FieldLabel('Deskripsi'),
            TextFormField(
              controller: _content,
              maxLines: 6,
              maxLength: 5000,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Deskripsi wajib diisi' : null,
              decoration: const InputDecoration(hintText: 'Kapan terjadi, di mana, dan apa dampaknya?'),
            ),
            const SizedBox(height: 12),
            const FieldLabel('Foto pendukung', optional: true),
            PhotoPickerField(file: _attachment, onChanged: (f) => setState(() => _attachment = f), emptyLabel: 'Tambah foto kendala'),
          ]),
        ),
      ),
    );
  }
}
