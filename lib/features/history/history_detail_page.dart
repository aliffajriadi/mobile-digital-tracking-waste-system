import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../data/repository.dart';
import '../record/record_menu.dart';
import '../report/report_form_page.dart';

/// Detail satu transaksi dari riwayat. [type] memakai nilai type_log dari API.
class HistoryDetailPage extends StatefulWidget {
  final String type;
  final int id;
  const HistoryDetailPage({super.key, required this.type, required this.id});

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  late Future<Map<String, dynamic>> _future;

  TxType get _tx => TxType.fromLog(widget.type);

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<Map<String, dynamic>> _fetch() => switch (widget.type) {
        'input_masuk' => Repo.entryDetail(widget.id),
        'input_keluar' => Repo.outDetail(widget.id),
        'olahan' => Repo.processedDetail(widget.id),
        _ => Repo.reportDetail(widget.id),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail ${_tx.label}')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) {
            final e = snap.error;
            return ErrorView(
              message: e is ApiException ? e.message : 'Terjadi kesalahan.',
              onRetry: () => setState(() => _future = _fetch()),
            );
          }
          final d = snap.data!;
          return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
            ..._content(d),
            if (widget.type != 'kendala') ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => openRecordFlow(context, const ReportFormPage()),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Ada kesalahan data? Laporkan ke admin'),
              ),
            ],
          ]);
        },
      ),
    );
  }

  List<Widget> _content(Map<String, dynamic> d) {
    switch (widget.type) {
      case 'input_masuk':
        return [
          _Hero(
            type: _tx,
            title: (d['sub_kategori'] ?? '-').toString(),
            subtitle: (d['kategori'] ?? '').toString(),
            amount: Fmt.qtyUnit(Fmt.toDouble(d['jumlah']), d['satuan']?.toString()),
            badge: d['b3_code'] != null ? 'B3 ${d['b3_code']}' : null,
          ),
          const SizedBox(height: 16),
          _InfoCard(rows: [
            _InfoRow(Icons.event_rounded, 'Tanggal', '${d['waktu_tanggal'] ?? '-'}'),
            _InfoRow(Icons.schedule_rounded, 'Jam', '${d['waktu_jam'] ?? '-'}'),
            _InfoRow(Icons.place_outlined, 'Sumber', '${d['sumber'] ?? '-'}'),
            _InfoRow(Icons.notes_rounded, 'Catatan', _orDash(d['catatan'])),
          ]),
          _Photo(url: d['foto']),
        ];
      case 'input_keluar':
        final items = (d['items'] as List? ?? []).whereType<Map>().toList();
        final total = items.fold<double>(0, (s, i) => s + Fmt.toDouble(i['quantity']));
        return [
          _Hero(type: _tx, title: (d['method'] ?? '-').toString(), subtitle: d['destination']?.toString() ?? 'Tanpa tujuan', amount: '${items.length} item • ${Fmt.qty(total)} kg'),
          const SizedBox(height: 16),
          _ItemsCard(title: 'Item keluar', items: items),
          const SizedBox(height: 16),
          _InfoCard(rows: [
            _InfoRow(Icons.event_rounded, 'Waktu', '${d['date_label'] ?? '-'} • ${d['time_label'] ?? ''}'),
            if (d['buyer'] != null) _InfoRow(Icons.storefront_outlined, 'Pembeli', d['buyer'].toString()),
            if (d['total_revenue'] != null) _InfoRow(Icons.payments_outlined, 'Pendapatan', Fmt.rupiah(Fmt.toDouble(d['total_revenue']))),
            _InfoRow(Icons.notes_rounded, 'Catatan', _orDash(d['notes'])),
          ]),
          _Photo(url: d['photo_url']),
        ];
      case 'olahan':
        final materials = (d['raw_materials'] as List? ?? []).whereType<Map>().toList();
        return [
          _Hero(type: _tx, title: (d['name'] ?? '-').toString(), subtitle: 'Hasil olahan', amount: Fmt.qtyUnit(Fmt.toDouble(d['quantity']), d['unit']?.toString())),
          const SizedBox(height: 16),
          _ItemsCard(title: 'Bahan baku dipakai', items: materials),
          const SizedBox(height: 16),
          _InfoCard(rows: [
            _InfoRow(Icons.event_rounded, 'Waktu', '${d['date_label'] ?? '-'} • ${d['time_label'] ?? ''}'),
            _InfoRow(Icons.notes_rounded, 'Catatan', _orDash(d['notes'])),
          ]),
        ];
      default:
        return [
          _Hero(type: _tx, title: (d['title'] ?? '-').toString(), subtitle: (d['category_name'] ?? '').toString(), amount: null),
          const SizedBox(height: 16),
          _InfoCard(rows: [
            if (d['date_label'] != null) _InfoRow(Icons.event_rounded, 'Waktu', '${d['date_label']} • ${d['time_label'] ?? ''}'),
            _InfoRow(Icons.description_outlined, 'Deskripsi', _orDash(d['content'])),
          ]),
          _Photo(url: d['attachment_path']),
        ];
    }
  }

  String _orDash(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? '-' : s;
  }
}

class _Hero extends StatelessWidget {
  final TxType type;
  final String title;
  final String subtitle;
  final String? amount;
  final String? badge;
  const _Hero({required this.type, required this.title, required this.subtitle, required this.amount, this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: type.color.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(type.icon, color: type.color, size: 20),
          const SizedBox(width: 6),
          Text(type.label, style: TextStyle(color: type.color, fontWeight: FontWeight.w600, fontSize: 13)),
          const Spacer(),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(badge!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 11)),
            ),
        ]),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: AppColors.inkSoft)),
        if (amount != null) ...[
          const SizedBox(height: 10),
          Text(amount!, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: type.color)),
        ],
      ]),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(rows[i].icon, size: 20, color: AppColors.muted),
                const SizedBox(width: 12),
                SizedBox(width: 86, child: Text(rows[i].label, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13))),
                Expanded(child: Text(rows[i].value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, height: 1.4))),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final String title;
  final List<Map> items;
  const _ItemsCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (items.isEmpty) const Text('-', style: TextStyle(color: AppColors.inkSoft)),
          for (final i in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Icon(i['is_processed'] == true ? Icons.recycling_rounded : Icons.inventory_2_outlined, size: 18,
                    color: i['is_processed'] == true ? AppColors.olahan : AppColors.primary),
                const SizedBox(width: 10),
                Expanded(child: Text((i['name'] ?? '-').toString())),
                Text(Fmt.qtyUnit(Fmt.toDouble(i['quantity']), i['unit']?.toString()), style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final dynamic url;
  const _Photo({required this.url});

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConstants.fileUrl(url);
    if (resolved == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            insetPadding: const EdgeInsets.all(12),
            child: InteractiveViewer(child: Image.network(resolved)),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            resolved,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: 120,
              color: const Color(0xFFEFF3F6),
              alignment: Alignment.center,
              child: const Text('Foto tidak dapat dimuat', style: TextStyle(color: AppColors.inkSoft)),
            ),
          ),
        ),
      ),
    );
  }
}
