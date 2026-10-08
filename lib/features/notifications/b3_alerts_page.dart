import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../out/out_form_page.dart';
import '../record/record_menu.dart';

class B3AlertsPage extends StatefulWidget {
  const B3AlertsPage({super.key});

  @override
  State<B3AlertsPage> createState() => _B3AlertsPageState();
}

class _B3AlertsPageState extends State<B3AlertsPage> {
  late Future<List<B3Alert>> _future;

  @override
  void initState() {
    super.initState();
    _future = Repo.b3Alerts();
  }

  Future<void> _reload() async {
    setState(() => _future = Repo.b3Alerts());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peringatan Limbah B3')),
      body: FutureBuilder<List<B3Alert>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const SkeletonList(count: 3, height: 110);
          if (snap.hasError) {
            return ErrorView(message: snap.error is ApiException ? snap.error.toString() : 'Terjadi kesalahan.', onRetry: _reload);
          }
          final alerts = snap.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: alerts.isEmpty
                ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [
                    MessageView(
                      icon: Icons.verified_user_outlined,
                      title: 'Semua aman',
                      message: 'Tidak ada limbah B3 di gudang yang mendekati batas masa simpan.',
                      color: AppColors.success,
                    ),
                  ])
                : ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20), children: [
                    const Text(
                      'Limbah B3 harus diserahkan ke pihak berizin sebelum melewati masa simpan. Umur dihitung dari stok tertua yang belum keluar.',
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    for (final a in alerts) Padding(padding: const EdgeInsets.only(bottom: 12), child: _AlertCard(alert: a)),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        await openRecordFlow(context, const OutFormPage());
                        if (mounted) _reload();
                      },
                      icon: const Icon(Icons.north_east_rounded),
                      label: const Text('Catat Sampah Keluar'),
                    ),
                  ]),
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final B3Alert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final (color, label) = alert.daysLeft < 0
        ? (AppColors.danger, 'Lewat ${-alert.daysLeft} hari')
        : alert.daysLeft == 0
            ? (AppColors.danger, 'Batas hari ini')
            : alert.daysLeft <= 3
                ? (AppColors.keluar, 'Sisa ${alert.daysLeft} hari')
                : (AppColors.warning, 'Sisa ${alert.daysLeft} hari');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: color.withValues(alpha: 0.35))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.science_outlined, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(alert.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('Kode ${alert.code}', style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _meta('Stok', Fmt.qtyUnit(alert.stock, alert.unit)),
            _meta('Masuk sejak', alert.since != null ? Fmt.date(alert.since!) : '-'),
            _meta('Maks simpan', '${alert.retentionDays} hari'),
          ]),
        ]),
      ),
    );
  }

  Widget _meta(String label, String value) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      );
}
