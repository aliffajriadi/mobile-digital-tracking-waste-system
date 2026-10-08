import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_events.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import 'history_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const _filters = [
    ('', 'Semua', null),
    ('1', 'Masuk', TxType.masuk),
    ('3', 'Olahan', TxType.olahan),
    ('2', 'Keluar', TxType.keluar),
    ('4', 'Kendala', TxType.kendala),
  ];

  final _searchController = TextEditingController();
  Timer? _debounce;
  String _type = '';
  List<HistoryGroup>? _groups;
  int _total = 0;
  String? _error;
  bool _loading = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
    AppEvents.dataChanged.addListener(_load);
  }

  @override
  void dispose() {
    AppEvents.dataChanged.removeListener(_load);
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = ++_requestId;
    setState(() => _loading = true);
    try {
      final res = await Repo.history(search: _searchController.text.trim(), type: _type);
      // Abaikan respons lama jika pengguna sudah mengubah filter
      if (!mounted || id != _requestId) return;
      setState(() {
        _groups = res.groups;
        _total = res.total;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted && id == _requestId) setState(() => _error = e.message);
    } finally {
      if (mounted && id == _requestId) setState(() => _loading = false);
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Column(children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari jenis sampah, metode, atau judul…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _load();
                          },
                        ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final f in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        showCheckmark: false,
                        avatar: f.$3 == null ? null : Icon(f.$3!.icon, size: 16, color: f.$3!.color),
                        label: Text(f.$2),
                        selected: _type == f.$1,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _type == f.$1 ? AppColors.primaryDark : AppColors.inkSoft,
                        ),
                        onSelected: (_) {
                          setState(() => _type = f.$1);
                          _load();
                        },
                      ),
                    ),
                ]),
              ),
            ]),
          ),
        ),
      ),
      body: Column(children: [
        if (_loading && _groups != null) const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _body()),
      ]),
    );
  }

  Widget _body() {
    if (_groups == null) {
      return _error != null ? ErrorView(message: _error!, onRetry: _load) : const SkeletonList();
    }
    final groups = _groups!;
    return RefreshIndicator(
      onRefresh: _load,
      child: groups.isEmpty
          ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
              EmptyView(
                icon: Icons.receipt_long_outlined,
                title: _searchController.text.isEmpty && _type.isEmpty ? 'Belum ada riwayat' : 'Tidak ada hasil',
                message: _searchController.text.isEmpty && _type.isEmpty
                    ? 'Transaksi yang Anda catat akan muncul di sini.'
                    : 'Coba kata kunci atau filter lain.',
              ),
            ])
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: groups.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('$_total transaksi', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                  );
                }
                final g = groups[i - 1];
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 8),
                    child: Text(g.date, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.inkSoft)),
                  ),
                  Card(
                    child: Column(children: [
                      for (var j = 0; j < g.entries.length; j++) ...[
                        if (j > 0) const Divider(indent: 72),
                        _HistoryTile(entry: g.entries[j]),
                      ],
                    ]),
                  ),
                ]);
              },
            ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final type = TxType.fromLog(entry.type);
    final label = entry.title.contains(': ') ? entry.title.split(': ').skip(1).join(': ') : entry.title;
    // Kendala: judul laporan lebih informatif daripada kategorinya
    final isReport = entry.type == 'kendala';
    final title = isReport ? entry.amount : label;
    final meta = [isReport ? label : type.label, entry.time, if (entry.subtitle != null) entry.subtitle!];
    return ListTile(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HistoryDetailPage(type: entry.type, id: entry.id))),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: type.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(type.icon, color: type.color),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(meta.join(' • '), style: const TextStyle(fontSize: 12)),
      trailing: isReport
          ? const Icon(Icons.chevron_right_rounded, color: AppColors.muted)
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(entry.amount, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
    );
  }
}
