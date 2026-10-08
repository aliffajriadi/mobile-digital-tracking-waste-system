import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/form_widgets.dart';
import '../../core/widgets/option_sheet.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/stock_item_row.dart';
import '../../data/models.dart';
import '../../data/repository.dart';

class ProcessedFormPage extends StatefulWidget {
  const ProcessedFormPage({super.key});

  @override
  State<ProcessedFormPage> createState() => _ProcessedFormPageState();
}

class _MaterialRow {
  final StockItem item;
  final TextEditingController qty = TextEditingController();
  _MaterialRow(this.item);
}

class _ProcessedFormPageState extends State<ProcessedFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _notes = TextEditingController();

  bool _loading = true;
  String? _loadError;
  List<ProcessedType> _types = [];
  List<StockItem> _rawStocks = [];

  ProcessedType? _type;
  final List<_MaterialRow> _materials = [];
  DateTime _time = DateTime.now();
  bool _submitting = false;
  bool _submitted = false;

  bool get _dirty => _type != null || _qty.text.isNotEmpty || _materials.isNotEmpty || _notes.text.isNotEmpty;

  double get _totalMaterials => _materials.fold(0, (s, m) => s + (Fmt.parseDecimal(m.qty.text) ?? 0));

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _qty.dispose();
    _notes.dispose();
    for (final m in _materials) {
      m.qty.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([Repo.processedTypes(), Repo.stocks()]);
      if (!mounted) return;
      setState(() {
        _types = results[0] as List<ProcessedType>;
        _rawStocks = (results[1] as List<StockItem>).where((s) => !s.isProcessed).toList();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickType() async {
    final picked = await showOptionSheet<ProcessedType>(
      context,
      title: 'Jenis hasil olahan',
      selected: _type,
      emptyMessage: 'Belum ada jenis olahan. Hubungi admin.',
      options: _types
          .map((t) => SheetOption(
                value: t,
                title: t.name,
                subtitle: t.description,
                trailing: 'Stok ${Fmt.qtyUnit(t.stock, t.unit)}',
                leading: AppNetworkImage(url: t.photo, size: 40, radius: 10, fallbackIcon: Icons.recycling_rounded, color: AppColors.olahan),
              ))
          .toList(),
    );
    if (picked != null) setState(() => _type = picked);
  }

  Future<void> _addMaterial() async {
    final used = _materials.map((m) => m.item.key).toSet();
    final options = _rawStocks.where((s) => !used.contains(s.key)).toList()
      ..sort((a, b) => b.stock.compareTo(a.stock));
    final picked = await showOptionSheet<StockItem>(
      context,
      title: 'Pilih bahan baku',
      emptyMessage: 'Semua jenis sudah ditambahkan.',
      options: options
          .map((s) => SheetOption(
                value: s,
                title: s.name,
                subtitle: s.category,
                enabled: s.stock > 0,
                trailing: s.stock > 0 ? Fmt.qtyUnit(s.stock, s.unit) : 'Stok kosong',
              ))
          .toList(),
    );
    if (picked != null) setState(() => _materials.add(_MaterialRow(picked)));
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final valid = _formKey.currentState!.validate();
    if (_type == null || _materials.isEmpty || !valid) {
      AppFeedback.snack(context, 'Lengkapi isian yang ditandai merah.', type: FeedbackType.error);
      return;
    }
    setState(() => _submitting = true);
    try {
      final message = await Repo.submitProcessed(
        processedId: _type!.id,
        qty: Fmt.parseDecimal(_qty.text)!,
        time: _time,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        rawMaterials: {for (final m in _materials) m.item.rawId: Fmt.parseDecimal(m.qty.text)!},
      );
      if (mounted) Navigator.of(context).pop(message);
    } on ApiException catch (e) {
      // Matikan loading dulu agar tombol tidak berputar di belakang dialog error
      if (mounted) setState(() => _submitting = false);
      if (mounted) await AppFeedback.error(context, e);
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
        appBar: AppBar(title: const Text('Catat Hasil Olahan')),
        bottomNavigationBar: _loading || _loadError != null
            ? null
            : BottomActionBar(label: 'Simpan Hasil Olahan', loading: _submitting, onPressed: _submit),
        body: _loading
            ? const LoadingView(message: 'Memuat jenis olahan & stok…')
            : _loadError != null
                ? ErrorView(message: _loadError!, onRetry: _load)
                : Form(
                    key: _formKey,
                    child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
                      SectionCard(
                        title: '1. Hasil olahan',
                        subtitle: 'Produk yang dihasilkan dari pengolahan',
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          PickerField(
                            value: _type?.name,
                            placeholder: 'Pilih jenis olahan',
                            icon: Icons.recycling_rounded,
                            onTap: _pickType,
                            errorText: _submitted && _type == null ? 'Jenis olahan wajib dipilih' : null,
                          ),
                          const SizedBox(height: 16),
                          QuantityField(
                            controller: _qty,
                            unit: _type?.unit ?? 'kg',
                            label: 'Jumlah hasil',
                            onChanged: (_) => setState(() {}),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: '2. Bahan baku',
                        subtitle: 'Sampah mentah yang dipakai (mengurangi stok)',
                        trailing: TextButton.icon(
                          onPressed: _addMaterial,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Tambah'),
                        ),
                        child: Column(children: [
                          if (_materials.isEmpty)
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _addMaterial,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 22),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _submitted ? AppColors.danger : AppColors.line),
                                ),
                                child: Column(children: [
                                  Icon(Icons.add_circle_outline_rounded, color: _submitted ? AppColors.danger : AppColors.primary),
                                  const SizedBox(height: 6),
                                  Text(
                                    _submitted ? 'Tambahkan minimal 1 bahan baku' : 'Tambahkan bahan baku',
                                    style: TextStyle(color: _submitted ? AppColors.danger : AppColors.inkSoft, fontWeight: FontWeight.w600),
                                  ),
                                ]),
                              ),
                            ),
                          for (final m in _materials)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: StockItemRow(
                                key: ValueKey(m.item.key),
                                name: m.item.name,
                                unit: m.item.unit,
                                stock: m.item.stock,
                                controller: m.qty,
                                onChanged: (_) => setState(() {}),
                                onRemove: () {
                                  setState(() => _materials.remove(m));
                                  // Dispose setelah frame agar field yang sedang dilepas tidak memakai controller mati
                                  WidgetsBinding.instance.addPostFrameCallback((_) => m.qty.dispose());
                                },
                              ),
                            ),
                          if (_materials.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(children: [
                                const Expanded(child: Text('Total bahan baku', style: TextStyle(color: AppColors.inkSoft))),
                                Text(Fmt.qtyUnit(_totalMaterials, 'kg'), style: const TextStyle(fontWeight: FontWeight.w700)),
                              ]),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: '3. Detail lain',
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const FieldLabel('Waktu pengolahan'),
                          DateTimeField(value: _time, onChanged: (v) => setState(() => _time = v)),
                          const SizedBox(height: 16),
                          const FieldLabel('Catatan', optional: true),
                          TextFormField(
                            controller: _notes,
                            maxLines: 3,
                            maxLength: 1000,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(hintText: 'Misal: batch kompos minggu ke-2'),
                          ),
                        ]),
                      ),
                    ]),
                  ),
      ),
    );
  }
}
