import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class OutFormPage extends StatefulWidget {
  const OutFormPage({super.key});

  @override
  State<OutFormPage> createState() => _OutFormPageState();
}

class _OutRow {
  final StockItem item;
  final TextEditingController qty = TextEditingController();
  _OutRow(this.item);
}

class _OutFormPageState extends State<OutFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  final _revenue = TextEditingController();

  bool _loading = true;
  String? _loadError;
  List<WasteOutMethod> _methods = [];
  List<NamedItem> _destinations = [];
  List<NamedItem> _buyers = [];
  List<StockItem> _stocks = [];

  WasteOutMethod? _method;
  NamedItem? _destination;
  NamedItem? _buyer;
  final List<_OutRow> _rows = [];
  DateTime _time = DateTime.now();
  File? _photo;
  bool _submitting = false;
  bool _submitted = false;

  bool get _dirty => _method != null || _rows.isNotEmpty || _notes.text.isNotEmpty || _photo != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notes.dispose();
    _revenue.dispose();
    for (final r in _rows) {
      r.qty.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final r = await Future.wait([Repo.outMethods(), Repo.destinations(), Repo.buyers(), Repo.stocks()]);
      if (!mounted) return;
      setState(() {
        _methods = r[0] as List<WasteOutMethod>;
        _destinations = r[1] as List<NamedItem>;
        _buyers = r[2] as List<NamedItem>;
        _stocks = r[3] as List<StockItem>;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDestination() async {
    final picked = await showOptionSheet<NamedItem>(
      context,
      title: 'Tujuan sampah',
      selected: _destination,
      emptyMessage: 'Belum ada data tujuan.',
      options: _destinations.map((d) => SheetOption(value: d, title: d.name, subtitle: d.description)).toList(),
    );
    if (picked != null) setState(() => _destination = picked);
  }

  Future<void> _pickBuyer() async {
    final picked = await showOptionSheet<NamedItem>(
      context,
      title: 'Pembeli / pengepul',
      selected: _buyer,
      emptyMessage: 'Belum ada data pembeli. Hubungi admin.',
      options: _buyers.map((b) => SheetOption(value: b, title: b.name, subtitle: b.description)).toList(),
    );
    if (picked != null) setState(() => _buyer = picked);
  }

  Future<void> _addItem() async {
    final used = _rows.map((r) => r.item.key).toSet();
    final options = _stocks.where((s) => !used.contains(s.key)).toList()
      ..sort((a, b) {
        if (a.stock > 0 != b.stock > 0) return a.stock > 0 ? -1 : 1;
        return a.name.compareTo(b.name);
      });
    final picked = await showOptionSheet<StockItem>(
      context,
      title: 'Pilih sampah yang keluar',
      emptyMessage: 'Semua jenis sudah ditambahkan.',
      options: options
          .map((s) => SheetOption(
                value: s,
                title: s.name,
                subtitle: s.isProcessed ? 'Hasil olahan' : s.category,
                enabled: s.stock > 0,
                trailing: s.stock > 0 ? Fmt.qtyUnit(s.stock, s.unit) : 'Stok kosong',
                leading: Icon(s.isProcessed ? Icons.recycling_rounded : Icons.inventory_2_outlined,
                    color: s.isProcessed ? AppColors.olahan : AppColors.primary),
              ))
          .toList(),
    );
    if (picked != null) setState(() => _rows.add(_OutRow(picked)));
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final valid = _formKey.currentState!.validate();
    final selling = _method?.isSelling ?? false;
    if (!valid || _method == null || _rows.isEmpty || (selling && _buyer == null)) {
      AppFeedback.snack(context, 'Lengkapi isian yang ditandai merah.', type: FeedbackType.error);
      return;
    }
    setState(() => _submitting = true);
    try {
      final message = await Repo.submitWasteOut(
        methodId: _method!.id,
        destinationId: _destination?.id,
        buyerId: selling ? _buyer?.id : null,
        revenue: selling ? Fmt.parseDecimal(_revenue.text.replaceAll('.', '')) : null,
        items: {for (final r in _rows) r.item.key: Fmt.parseDecimal(r.qty.text)!},
        time: _time,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        photo: _photo,
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

  Widget _methodSelector() {
    if (_methods.isEmpty) {
      return const Text('Belum ada metode keluar. Hubungi admin.', style: TextStyle(color: AppColors.inkSoft));
    }
    return Column(children: [
      for (final m in _methods)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: _method == m ? AppColors.keluar.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _method = m),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _method == m ? AppColors.keluar : AppColors.line, width: _method == m ? 1.5 : 1),
                ),
                child: Row(children: [
                  AppNetworkImage(url: m.photo, size: 40, radius: 10, fallbackIcon: m.isSelling ? Icons.sell_outlined : Icons.local_shipping_outlined, color: AppColors.keluar),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if ((m.description ?? '').isNotEmpty)
                        Text(m.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    ]),
                  ),
                  Icon(_method == m ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: _method == m ? AppColors.keluar : AppColors.muted),
                ]),
              ),
            ),
          ),
        ),
      if (_submitted && _method == null)
        const Align(alignment: Alignment.centerLeft, child: Text('Metode wajib dipilih', style: TextStyle(color: AppColors.danger, fontSize: 12))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final selling = _method?.isSelling ?? false;
    return UnsavedChangesGuard(
      hasChanges: _dirty && !_submitting,
      child: Scaffold(
        appBar: AppBar(title: const Text('Catat Sampah Keluar')),
        bottomNavigationBar: _loading || _loadError != null
            ? null
            : BottomActionBar(label: 'Simpan Sampah Keluar', loading: _submitting, onPressed: _submit),
        body: _loading
            ? const LoadingView(message: 'Memuat metode & stok…')
            : _loadError != null
                ? ErrorView(message: _loadError!, onRetry: _load)
                : Form(
                    key: _formKey,
                    child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
                      SectionCard(title: '1. Metode keluar', child: _methodSelector()),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: '2. Sampah yang keluar',
                        subtitle: 'Stok gudang akan berkurang sesuai jumlah',
                        trailing: TextButton.icon(onPressed: _addItem, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Tambah')),
                        child: Column(children: [
                          if (_rows.isEmpty)
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _addItem,
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
                                  Text(_submitted ? 'Tambahkan minimal 1 item' : 'Tambahkan item sampah',
                                      style: TextStyle(color: _submitted ? AppColors.danger : AppColors.inkSoft, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            ),
                          for (final r in _rows)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: StockItemRow(
                                key: ValueKey(r.item.key),
                                name: r.item.name,
                                unit: r.item.unit,
                                stock: r.item.stock,
                                controller: r.qty,
                                badge: r.item.isProcessed ? 'Olahan' : null,
                                color: AppColors.olahan,
                                onChanged: (_) => setState(() {}),
                                onRemove: () {
                                  setState(() => _rows.remove(r));
                                  WidgetsBinding.instance.addPostFrameCallback((_) => r.qty.dispose());
                                },
                              ),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: '3. Tujuan & penjualan',
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const FieldLabel('Tujuan', optional: true),
                          PickerField(value: _destination?.name, placeholder: 'Pilih tujuan', icon: Icons.place_outlined, onTap: _pickDestination),
                          if (selling) ...[
                            const SizedBox(height: 16),
                            const FieldLabel('Pembeli'),
                            PickerField(
                              value: _buyer?.name,
                              placeholder: 'Pilih pembeli / pengepul',
                              icon: Icons.storefront_outlined,
                              onTap: _pickBuyer,
                              errorText: _submitted && _buyer == null ? 'Pembeli wajib dipilih untuk penjualan' : null,
                            ),
                            const SizedBox(height: 16),
                            const FieldLabel('Total pendapatan'),
                            TextFormField(
                              controller: _revenue,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) => selling && (v == null || v.isEmpty) ? 'Total pendapatan wajib diisi' : null,
                              decoration: const InputDecoration(prefixText: 'Rp ', hintText: '0'),
                            ),
                          ],
                        ]),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: '4. Bukti & catatan',
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const FieldLabel('Waktu keluar'),
                          DateTimeField(value: _time, onChanged: (v) => setState(() => _time = v)),
                          const SizedBox(height: 16),
                          const FieldLabel('Foto bukti', optional: true),
                          PhotoPickerField(file: _photo, onChanged: (f) => setState(() => _photo = f), emptyLabel: 'Foto armada / nota'),
                          const SizedBox(height: 16),
                          const FieldLabel('Catatan', optional: true),
                          TextFormField(
                            controller: _notes,
                            maxLines: 3,
                            maxLength: 1000,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(hintText: 'Misal: nomor polisi truk, nama penerima'),
                          ),
                        ]),
                      ),
                    ]),
                  ),
      ),
    );
  }
}
