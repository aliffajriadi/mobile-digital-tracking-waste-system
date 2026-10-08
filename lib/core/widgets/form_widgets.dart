import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'ruler_picker_modal.dart';

/// Kartu putih pembungkus satu bagian form.
class SectionCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title != null) ...[
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                    ),
                ]),
              ),
              ?trailing,
            ]),
            const SizedBox(height: 14),
          ],
          child,
        ]),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  final bool optional;
  const FieldLabel(this.text, {super.key, this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.ink)),
        if (optional) const TextSpan(text: '  (opsional)', style: TextStyle(fontSize: 12, color: AppColors.muted)),
      ])),
    );
  }
}

/// Field yang dibuka dengan tap (memilih dari bottom sheet / date picker).
class PickerField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final IconData icon;
  final VoidCallback? onTap;
  final String? errorText;
  final String? helper;
  final bool loading;

  const PickerField({
    super.key,
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.onTap,
    this.errorText,
    this.helper,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: loading ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: errorText != null ? AppColors.danger : AppColors.line),
            ),
            child: Row(children: [
              Icon(icon, color: hasValue ? AppColors.primary : AppColors.muted, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loading ? 'Memuat…' : (hasValue ? value! : placeholder),
                  style: TextStyle(
                    fontSize: 14,
                    color: hasValue ? AppColors.ink : AppColors.muted,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (loading)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              else
                const Icon(Icons.expand_more_rounded, color: AppColors.muted),
            ]),
          ),
        ),
      ),
      if (errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(errorText!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
        )
      else if (helper != null)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(helper!, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
        ),
    ]);
  }
}

/// Input berat/jumlah dengan satuan, tombol penggaris, dan info stok tersedia.
/// Menerima desimal dengan koma maupun titik.
class QuantityField extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final String label;
  final double? maxStock;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  const QuantityField({
    super.key,
    required this.controller,
    this.unit = 'kg',
    this.label = 'Berat',
    this.maxStock,
    this.errorText,
    this.autofocus = false,
    this.onChanged,
  });

  static String? validate(String? value, {double? maxStock, String unit = 'kg'}) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    final qty = Fmt.parseDecimal(value);
    if (qty == null) return 'Masukkan angka yang valid';
    if (qty <= 0) return 'Harus lebih dari 0';
    if (maxStock != null && qty > maxStock + 0.0001) {
      return 'Melebihi stok tersedia (${Fmt.qtyUnit(maxStock, unit)})';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FieldLabel(label),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            autofocus: autofocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            onChanged: onChanged,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) => validate(v, maxStock: maxStock, unit: unit),
            decoration: InputDecoration(
              hintText: '0',
              errorText: errorText,
              suffixText: unit,
              suffixStyle: const TextStyle(fontSize: 15, color: AppColors.inkSoft, fontWeight: FontWeight.w600),
              helperText: maxStock != null ? 'Stok tersedia: ${Fmt.qtyUnit(maxStock, unit)}' : null,
              helperStyle: const TextStyle(color: AppColors.inkSoft),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 62,
          width: 56,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(56, 62)),
            onPressed: () async {
              FocusScope.of(context).unfocus();
              final current = Fmt.parseDecimal(controller.text) ?? 0;
              final max = maxStock != null && maxStock! > 0 ? maxStock! : 500.0;
              final picked = await showRulerPickerModal(context, initialValue: current.clamp(0, max), max: max, unit: unit);
              if (picked != null) {
                controller.text = Fmt.qty(picked).replaceAll('.', '');
                onChanged?.call(controller.text);
              }
            },
            child: const Icon(Icons.straighten_rounded, color: AppColors.primary),
          ),
        ),
      ]),
    ]);
  }
}

/// Field waktu transaksi. Tidak bisa memilih waktu di masa depan.
class DateTimeField extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  const DateTimeField({super.key, required this.value, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: value.isAfter(now) ? now : value,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      helpText: 'Tanggal transaksi',
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
      helpText: 'Jam transaksi',
    );
    if (time == null) return;
    var picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (picked.isAfter(now)) picked = now;
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final isNow = DateTime.now().difference(value).inMinutes.abs() < 2;
    return PickerField(
      value: isNow ? 'Sekarang • ${Fmt.dateTime(value)}' : Fmt.dateTime(value),
      placeholder: 'Pilih waktu',
      icon: Icons.schedule_rounded,
      onTap: () => _pick(context),
      helper: 'Ubah jika mencatat transaksi susulan.',
    );
  }
}

/// Pemilih foto bukti dari kamera atau galeri, dengan pratinjau.
class PhotoPickerField extends StatelessWidget {
  final File? file;
  final ValueChanged<File?> onChanged;
  final String? errorText;
  final String emptyLabel;

  const PhotoPickerField({
    super.key,
    required this.file,
    required this.onChanged,
    this.errorText,
    this.emptyLabel = 'Tambah foto bukti',
  });

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
            title: const Text('Ambil dari kamera'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
            title: const Text('Pilih dari galeri'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (source == null) return;
    try {
      // Dikompres agar upload cepat & di bawah batas ukuran server
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 70, maxWidth: 1600);
      if (picked != null) onChanged(File(picked.path));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka kamera/galeri. Periksa izin aplikasi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = errorText != null ? AppColors.danger : AppColors.line;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (file == null)
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _pick(context),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 32),
              const SizedBox(height: 8),
              Text(emptyLabel, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
            ]),
          ),
        )
      else
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(file!, height: 190, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Row(children: [
              _roundButton(Icons.edit_rounded, () => _pick(context)),
              const SizedBox(width: 8),
              _roundButton(Icons.delete_rounded, () => onChanged(null)),
            ]),
          ),
        ]),
      if (errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(errorText!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
        ),
    ]);
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) => Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: Colors.white, size: 18)),
        ),
      );
}

/// Tombol simpan yang menempel di bawah layar.
class BottomActionBar extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final IconData icon;
  final Widget? summary;

  const BottomActionBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon = Icons.check_rounded,
    this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (summary != null) ...[summary!, const SizedBox(height: 10)],
        FilledButton.icon(
          onPressed: loading ? null : onPressed,
          icon: loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
              : Icon(icon),
          label: Text(loading ? 'Menyimpan…' : label),
        ),
      ]),
    );
  }
}

/// Tanya konfirmasi sebelum meninggalkan form yang sudah diisi.
class UnsavedChangesGuard extends StatelessWidget {
  final bool hasChanges;
  final Widget child;
  const UnsavedChangesGuard({super.key, required this.hasChanges, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Batalkan pengisian?'),
            content: const Text('Data yang sudah Anda isi belum disimpan dan akan hilang.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Lanjut mengisi')),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44), backgroundColor: AppColors.danger),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Buang'),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) Navigator.of(context).pop();
      },
      child: child,
    );
  }
}
