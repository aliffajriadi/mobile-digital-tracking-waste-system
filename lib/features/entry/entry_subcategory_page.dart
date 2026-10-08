import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import 'entry_category_page.dart';
import 'entry_form_page.dart';

class EntrySubcategoryPage extends StatefulWidget {
  final WasteCategory category;
  const EntrySubcategoryPage({super.key, required this.category});

  @override
  State<EntrySubcategoryPage> createState() => _EntrySubcategoryPageState();
}

class _EntrySubcategoryPageState extends State<EntrySubcategoryPage> {
  late Future<List<WasteSubCategory>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = Repo.subCategories(widget.category.id);
  }

  Future<void> _open(WasteSubCategory sub) async {
    final saved = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => EntryFormPage(category: widget.category, subCategory: sub)),
    );
    if (saved != null && mounted) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(widget.category.name);
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: FutureBuilder<List<WasteSubCategory>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const SkeletonList(count: 6);
          if (snap.hasError) {
            return ErrorView(
              message: snap.error is ApiException ? snap.error.toString() : 'Terjadi kesalahan.',
              onRetry: () => setState(() => _future = Repo.subCategories(widget.category.id)),
            );
          }
          final all = snap.data!;
          final items = all.where((s) => _query.isEmpty || s.name.toLowerCase().contains(_query.toLowerCase())).toList();
          return ListView(padding: const EdgeInsets.all(20), children: [
            const EntryStepHeader(step: 2, title: 'Pilih jenis sampah'),
            const SizedBox(height: 14),
            if (all.length > 6) ...[
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(hintText: 'Cari jenis sampah…', prefixIcon: Icon(Icons.search_rounded)),
              ),
              const SizedBox(height: 14),
            ],
            if (all.isEmpty)
              const EmptyView(icon: Icons.inventory_2_outlined, title: 'Belum ada jenis sampah aktif', message: 'Hubungi admin untuk menambahkan sub-kategori.')
            else if (items.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Tidak ditemukan.')))
            else
              for (final s in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      onTap: () => _open(s),
                      leading: AppNetworkImage(url: s.photo, size: 48, fallbackIcon: categoryIcon(widget.category.name), color: color),
                      title: Row(children: [
                        Flexible(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                        if (s.isB3) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                            child: const Text('B3', style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ]),
                      subtitle: Text('Stok gudang: ${Fmt.qtyUnit(s.stock, s.unit)}', style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                    ),
                  ),
                ),
          ]);
        },
      ),
    );
  }
}
