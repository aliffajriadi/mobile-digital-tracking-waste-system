import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/form_widgets.dart';
import '../../core/widgets/option_sheet.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import 'entry_category_page.dart';

class EntryFormPage extends StatefulWidget {
  final WasteCategory category;
  final WasteSubCategory subCategory;
  const EntryFormPage({super.key, required this.category, required this.subCategory});

  @override
  State<EntryFormPage> createState() => _EntryFormPageState();
}

class _EntryFormPageState extends State<EntryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _notes = TextEditingController();

  List<NamedItem> _locations = [];
  bool _loadingLocations = true;
  String? _locationsError;
  NamedItem? _location;
  DateTime _time = DateTime.now();
  File? _photo;
  bool _submitting = false;
  bool _submitted = false;
  ApiException? _serverError;

  bool get _dirty => _qty.text.isNotEmpty || _notes.text.isNotEmpty || _photo != null || _location != null;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _qty.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _loadingLocations = true;
      _locationsError = null;
    });
    try {
      final list = await Repo.sourceLocations();
      if (!mounted) return;
      setState(() {
        _locations = list;
        if (list.length == 1) _location = list.first;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _locationsError = e.message);
    } finally {
      if (mounted) setState(() => _loadingLocations = false);
    }
  }

  Future<void> _pickLocation() async {
    if (_locationsError != null) {
      await _loadLocations();
      return;
    }
    final picked = await showOptionSheet<NamedItem>(
      context,
      title: 'Sumber sampah',
      selected: _location,
      emptyMessage: 'Belum ada sumber lokasi. Hubungi admin.',
      options: _locations
          .map((l) => SheetOption(
                value: l,
                title: l.name,
                subtitle: l.description,
                leading: AppNetworkImage(url: l.photo, size: 40, radius: 10, fallbackIcon: Icons.place_outlined),
              ))
          .toList(),
    );
    if (picked != null) setState(() => _location = picked);
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _serverError = null;
    });
    final valid = _formKey.currentState!.validate();
    if (!valid || _location == null || _photo == null) {
      AppFeedback.snack(context, 'Lengkapi isian yang ditandai merah.', type: FeedbackType.error);
      return;
    }

    setState(() => _submitting = true);
    try {
      final message = await Repo.submitWasteEntry(
        subCategoryId: widget.subCategory.id,
        locationId: _location!.id,
        qty: Fmt.parseDecimal(_qty.text)!,
        time: _time,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        photo: _photo,
      );
      if (!mounted) return;
      Navigator.of(context).pop(message);
    } on ApiException catch (e) {
      // Matikan loading dulu agar tombol tidak berputar di belakang dialog error
      if (mounted) setState(() => _submitting = false);
      if (!mounted) return;
      setState(() => _serverError = e);
      await AppFeedback.error(context, e);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppFeedback.snack(context, 'Terjadi kesalahan tak terduga. Silakan coba lagi.', type: FeedbackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subCategory;
    final color = categoryColor(widget.category.name);

    return UnsavedChangesGuard(
      hasChanges: _dirty && !_submitting,
      child: Scaffold(
        appBar: AppBar(title: const Text('Catat Sampah Masuk')),
        bottomNavigationBar: BottomActionBar(label: 'Simpan Sampah Masuk', loading: _submitting, onPressed: _submit),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
            const EntryStepHeader(step: 3, title: 'Isi detail timbangan'),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  AppNetworkImage(url: sub.photo, size: 56, fallbackIcon: categoryIcon(widget.category.name), color: color),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(widget.category.name, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('Stok saat ini ${Fmt.qtyUnit(sub.stock, sub.unit)}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                    ]),
                  ),
                ]),
              ),
            ),
            if (sub.isB3) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Limbah B3 (${sub.b3Code}). Gunakan APD dan simpan terpisah.'
                      '${sub.b3RetentionDays != null ? ' Masa simpan maksimal ${sub.b3RetentionDays} hari.' : ''}',
                      style: const TextStyle(color: AppColors.danger, fontSize: 13, height: 1.4),
                    ),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 20),
            QuantityField(
              controller: _qty,
              unit: sub.unit,
              label: 'Berat timbangan',
              autofocus: true,
              errorText: _serverError?.fieldError('measured_qty'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            const FieldLabel('Sumber sampah'),
            PickerField(
              value: _locationsError != null ? null : _location?.name,
              placeholder: _locationsError != null ? 'Gagal memuat — ketuk untuk coba lagi' : 'Pilih asal sampah',
              icon: Icons.place_outlined,
              loading: _loadingLocations,
              onTap: _pickLocation,
              errorText: _submitted && _location == null ? 'Sumber sampah wajib dipilih' : _serverError?.fieldError('id_source_location_waste'),
            ),
            const SizedBox(height: 20),
            const FieldLabel('Waktu'),
            DateTimeField(value: _time, onChanged: (v) => setState(() => _time = v)),
            const SizedBox(height: 20),
            const FieldLabel('Foto bukti'),
            PhotoPickerField(
              file: _photo,
              onChanged: (f) => setState(() => _photo = f),
              emptyLabel: 'Foto sampah di timbangan',
              errorText: _submitted && _photo == null ? 'Foto bukti wajib dilampirkan' : _serverError?.fieldError('photo'),
            ),
            const SizedBox(height: 20),
            const FieldLabel('Catatan', optional: true),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Misal: kondisi sampah basah, tercampur, dll.'),
            ),
          ]),
        ),
      ),
    );
  }
}
