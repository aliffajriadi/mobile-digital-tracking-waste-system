import 'package:flutter/material.dart';

import '../../core/app_events.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../entry/entry_category_page.dart';
import '../entry/entry_subcategory_page.dart';
import '../history/history_detail_page.dart';
import '../iot/iot_page.dart';
import '../notifications/b3_alerts_page.dart';
import '../out/out_form_page.dart';
import '../processed/processed_form_page.dart';
import '../record/record_menu.dart';
import '../report/report_form_page.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback onOpenStock;
  final VoidCallback onOpenHistory;
  const DashboardPage({super.key, required this.onOpenStock, required this.onOpenHistory});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Repo.dashboard();
      if (mounted) setState(() => _data = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return Scaffold(
        body: SafeArea(
          child: _loading ? const LoadingView() : ErrorView(message: _error ?? 'Gagal memuat.', onRetry: _load),
        ),
      );
    }

    final d = _data!;
    final summary = Map<String, dynamic>.from(d['today_summary'] ?? {});
    final categories = (d['categories'] as List? ?? []).whereType<Map>().map((e) => WasteCategory.fromJson(Map<String, dynamic>.from(e))).toList();
    final recent = (d['recent_entries'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final b3Count = int.tryParse(d['b3_alert_count']?.toString() ?? '') ?? 0;
    final name = (d['full_name'] ?? '').toString();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
          SliverToBoxAdapter(
            // Header & kartu ringkasan dalam satu Column agar kartu tergambar di atas header
            child: Column(children: [
              _Header(name: name, photo: d['user_photo_url'] ?? d['user_photo'], b3Count: b3Count, onRefreshNeeded: _load),
              Transform.translate(
                offset: const Offset(0, -36),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    _TodaySummary(summary: summary),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: widget.onOpenStock,
                        icon: const Icon(Icons.inventory_2_outlined, size: 18),
                        label: const Text('Lihat stok gudang'),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverList.list(children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Data mungkin belum terbaru: $_error', style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                ),
              if (b3Count > 0) ...[
                _B3Banner(count: b3Count, onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const B3AlertsPage()));
                }),
                const SizedBox(height: 20),
              ],
              const _SectionTitle('Catat cepat'),
              const SizedBox(height: 10),
              Row(children: [
                _QuickAction(type: TxType.masuk, label: 'Masuk', onTap: () => openRecordFlow(context, const EntryCategoryPage())),
                _QuickAction(type: TxType.olahan, label: 'Olahan', onTap: () => openRecordFlow(context, const ProcessedFormPage())),
                _QuickAction(type: TxType.keluar, label: 'Keluar', onTap: () => openRecordFlow(context, const OutFormPage())),
                _QuickAction(type: TxType.kendala, label: 'Kendala', onTap: () => openRecordFlow(context, const ReportFormPage())),
              ]),
              const SizedBox(height: 12),
              _IotCard(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IotPage()))),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _SectionTitle('Timbang per kategori'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 112,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final c = categories[i];
                      final color = categoryColor(c.name);
                      return SizedBox(
                        width: 128,
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => openRecordFlow(context, EntrySubcategoryPage(category: c)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                AppNetworkImage(url: c.photo, size: 36, radius: 10, fallbackIcon: categoryIcon(c.name), color: color),
                                Flexible(
                                  child: Text(c.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(children: [
                const Expanded(child: _SectionTitle('Sampah masuk hari ini')),
                TextButton(onPressed: widget.onOpenHistory, child: const Text('Riwayat')),
              ]),
              const SizedBox(height: 4),
              if (recent.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    child: Column(children: [
                      const Icon(Icons.scale_outlined, color: AppColors.muted, size: 32),
                      const SizedBox(height: 8),
                      const Text('Belum ada timbangan hari ini', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      const Text('Ketuk "Masuk" untuk mulai mencatat.', style: TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                    ]),
                  ),
                )
              else
                Card(
                  child: Column(children: [
                    for (var i = 0; i < recent.length; i++) ...[
                      if (i > 0) const Divider(indent: 72),
                      _RecentTile(entry: recent[i]),
                    ],
                  ]),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final dynamic photo;
  final int b3Count;
  final VoidCallback onRefreshNeeded;
  const _Header({required this.name, required this.photo, required this.b3Count, required this.onRefreshNeeded});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 12, 52),
      child: Row(children: [
        UserAvatar(name: name, photo: photo?.toString(), size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(Fmt.greeting(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(name.isEmpty ? 'PIC' : name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
        ),
        IconButton(
          tooltip: 'Peringatan B3',
          onPressed: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const B3AlertsPage()));
            onRefreshNeeded();
          },
          icon: Badge(
            isLabelVisible: b3Count > 0,
            label: Text('$b3Count'),
            child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
          ),
        ),
      ]),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _TodaySummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    Widget cell(TxType type, String label, String weightKey, String countKey) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [
            Icon(type.icon, color: type.color, size: 22),
            const SizedBox(height: 6),
            Text(Fmt.qty(Fmt.toDouble(summary[weightKey])), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text('kg $label', style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
            Text('${summary[countKey] ?? 0} transaksi', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          ]),
        ),
      );
    }

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
        child: Column(children: [
          Text('Hari ini • ${Fmt.date(DateTime.now())}', style: const TextStyle(fontSize: 12, color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(children: [
              cell(TxType.masuk, 'masuk', 'berat_masuk', 'total_masuk'),
              const VerticalDivider(width: 1),
              cell(TxType.olahan, 'diolah', 'berat_diolah', 'sudah_diolah'),
              const VerticalDivider(width: 1),
              cell(TxType.keluar, 'keluar', 'berat_keluar', 'sampah_keluar'),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _B3Banner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _B3Banner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.danger.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Icon(Icons.science_outlined, color: AppColors.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Text('$count limbah B3 mendekati / melewati batas masa simpan', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.danger),
          ]),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
}

class _QuickAction extends StatelessWidget {
  final TxType type;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.type, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: type.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(type.icon, color: type.color),
                ),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _IotCard extends StatelessWidget {
  final VoidCallback onTap;
  const _IotCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.scale_rounded, color: AppColors.primary),
          ),
          title: const Text('Timbangan IoT', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Hubungkan timbangan agar berat tercatat otomatis', style: TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _RecentTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final sub = entry['sub_category'] is Map ? Map<String, dynamic>.from(entry['sub_category']) : <String, dynamic>{};
    final unit = sub['unit_measured'] is Map ? (sub['unit_measured']['symbol'] ?? 'kg').toString() : 'kg';
    final created = DateTime.tryParse(entry['created_at']?.toString() ?? '')?.toLocal();
    final isIot = entry['notes'] == 'Timbangan Otomatis (IoT)';
    final location = entry['source_location'] is Map ? entry['source_location']['name']?.toString() : null;

    return ListTile(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => HistoryDetailPage(type: 'input_masuk', id: int.tryParse(entry['id'].toString()) ?? 0),
      )),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: AppColors.masuk.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(isIot ? Icons.scale_rounded : TxType.masuk.icon, color: AppColors.masuk),
      ),
      title: Text((sub['name'] ?? 'Sampah').toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        [if (created != null) Fmt.time(created), if (isIot) 'Timbangan IoT' else ?location].join(' • '),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(Fmt.qtyUnit(Fmt.toDouble(entry['measured_qty']), unit), style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
