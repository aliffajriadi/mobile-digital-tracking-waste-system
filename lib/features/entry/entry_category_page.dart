import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import 'entry_subcategory_page.dart';

class EntryCategoryPage extends StatefulWidget {
  const EntryCategoryPage({super.key});

  @override
  State<EntryCategoryPage> createState() => _EntryCategoryPageState();
}

class _EntryCategoryPageState extends State<EntryCategoryPage> {
  late Future<List<WasteCategory>> _future;

  @override
  void initState() {
    super.initState();
    _future = Repo.categories();
  }

  Future<void> _open(WasteCategory category) async {
    final saved = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => EntrySubcategoryPage(category: category)),
    );
    if (saved != null && mounted) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sampah Masuk')),
      body: FutureBuilder<List<WasteCategory>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const SkeletonList(count: 4, height: 88);
          if (snap.hasError) {
            return ErrorView(
              message: snap.error is ApiException ? snap.error.toString() : 'Terjadi kesalahan.',
              onRetry: () => setState(() => _future = Repo.categories()),
            );
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const EmptyView(icon: Icons.category_outlined, title: 'Belum ada kategori', message: 'Hubungi admin untuk menambahkan kategori sampah.');
          }
          return ListView(padding: const EdgeInsets.all(20), children: [
            const EntryStepHeader(step: 1, title: 'Pilih kategori sampah'),
            const SizedBox(height: 14),
            for (final c in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _open(c),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        AppNetworkImage(url: c.photo, size: 60, fallbackIcon: _iconFor(c.name), color: _colorFor(c.name)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            if ((c.description ?? '').isNotEmpty)
                              Text(c.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                            if (c.subCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('${c.subCount} jenis', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                              ),
                          ]),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                      ]),
                    ),
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

IconData _iconFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('anorganik') || n.contains('non organik')) return Icons.layers_outlined;
  if (n.contains('organik')) return Icons.eco_outlined;
  if (n.contains('b3')) return Icons.science_outlined;
  return Icons.delete_outline_rounded;
}

Color _colorFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('anorganik') || n.contains('non organik')) return const Color(0xFFF2994A);
  if (n.contains('organik')) return AppColors.primary;
  if (n.contains('b3')) return AppColors.danger;
  return const Color(0xFF64748B);
}

/// Penanda langkah alur sampah masuk (dipakai juga di halaman berikutnya).
class EntryStepHeader extends StatelessWidget {
  final int step;
  final String title;
  const EntryStepHeader({super.key, required this.step, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.masuk, shape: BoxShape.circle),
        child: Text('$step', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
      const SizedBox(width: 8),
      Text('$step/3', style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }
}

IconData categoryIcon(String name) => _iconFor(name);
Color categoryColor(String name) => _colorFor(name);
