import 'package:flutter/material.dart';

import '../../core/app_events.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../out/out_form_page.dart';
import '../processed/processed_form_page.dart';
import '../record/record_menu.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  List<StockItem>? _items;
  String? _error;
  String _query = '';
  String _filter = 'all';
  bool _hideEmpty = true;

  @override
  void initState() {
    super.initState();
    _load();
    AppEvents.dataChanged.addListener(_load);
  }

  @override
  void dispose() {
    AppEvents.dataChanged.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await Repo.stocks();
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stok Gudang')),
      body: _items == null
          ? (_error != null ? ErrorView(message: _error!, onRetry: _load) : const SkeletonList())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final items = _items!;
    final categories = <String>{for (final i in items) if (!i.isProcessed) i.category}.toList()..sort();

    var filtered = items.where((i) {
      if (_query.isNotEmpty && !i.name.toLowerCase().contains(_query.toLowerCase())) return false;
      if (_hideEmpty && i.stock.abs() < 0.0001) return false;
      return switch (_filter) {
        'all' => true,
        'processed' => i.isProcessed,
        'b3' => i.isB3,
        _ => !i.isProcessed && i.category == _filter,
      };
    }).toList()
      ..sort((a, b) => b.stock.compareTo(a.stock));

    final rawTotal = items.where((i) => !i.isProcessed && i.unit == 'kg').fold<double>(0, (s, i) => s + i.stock);
    final processedTotal = items.where((i) => i.isProcessed && i.unit == 'kg').fold<double>(0, (s, i) => s + i.stock);
    final maxStock = filtered.isEmpty ? 1.0 : filtered.map((i) => i.stock).reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
        Row(children: [
          Expanded(child: _TotalCard(label: 'Sampah mentah', value: rawTotal, color: AppColors.primary, icon: Icons.inventory_2_rounded)),
          const SizedBox(width: 12),
          Expanded(child: _TotalCard(label: 'Hasil olahan', value: processedTotal, color: AppColors.olahan, icon: Icons.recycling_rounded)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              onPressed: () => openRecordFlow(context, const ProcessedFormPage()),
              icon: const Icon(Icons.recycling_rounded, size: 18, color: AppColors.olahan),
              label: const Text('Olah', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              onPressed: () => openRecordFlow(context, const OutFormPage()),
              icon: const Icon(Icons.north_east_rounded, size: 18, color: AppColors.keluar),
              label: const Text('Keluarkan', style: TextStyle(fontSize: 13)),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(hintText: 'Cari jenis sampah…', prefixIcon: Icon(Icons.search_rounded), contentPadding: EdgeInsets.symmetric(vertical: 12)),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _chip('all', 'Semua'),
            for (final c in categories) _chip(c, c),
            _chip('processed', 'Hasil Olahan'),
            if (items.any((i) => i.isB3)) _chip('b3', 'Limbah B3'),
          ]),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _hideEmpty,
          onChanged: (v) => setState(() => _hideEmpty = v),
          title: const Text('Sembunyikan stok kosong', style: TextStyle(fontSize: 13)),
        ),
        if (_error != null)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))),
        if (filtered.isEmpty)
          const EmptyView(icon: Icons.inventory_2_outlined, title: 'Tidak ada stok', message: 'Coba ubah filter atau catat sampah masuk.')
        else
          Card(
            child: Column(children: [
              for (var i = 0; i < filtered.length; i++) ...[
                if (i > 0) const Divider(indent: 16, endIndent: 16),
                _StockTile(item: filtered[i], maxStock: maxStock.toDouble()),
              ],
            ]),
          ),
      ]),
    );
  }

  Widget _chip(String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _filter = value),
        labelStyle: TextStyle(color: selected ? AppColors.primaryDark : AppColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  const _TotalCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text('${Fmt.qty(value)} kg', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
        ]),
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  final StockItem item;
  final double maxStock;
  const _StockTile({required this.item, required this.maxStock});

  @override
  Widget build(BuildContext context) {
    final color = item.isProcessed ? AppColors.olahan : AppColors.primary;
    final negative = item.stock < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                if (item.isB3) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('B3 ${item.b3Code ?? ''}', style: const TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
              Text(item.category, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ]),
          ),
          Text(
            Fmt.qtyUnit(item.stock, item.unit),
            style: TextStyle(fontWeight: FontWeight.w700, color: negative ? AppColors.danger : (item.stock > 0 ? AppColors.ink : AppColors.muted)),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: item.stock <= 0 ? 0 : (item.stock / maxStock).clamp(0.02, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFEFF3F6),
            color: color,
          ),
        ),
      ]),
    );
  }
}
