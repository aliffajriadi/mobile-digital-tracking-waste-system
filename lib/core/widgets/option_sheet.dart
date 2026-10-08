import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SheetOption<T> {
  final T value;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool enabled;
  final String? trailing;

  const SheetOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.leading,
    this.enabled = true,
    this.trailing,
  });
}

/// Bottom sheet daftar pilihan dengan pencarian (otomatis muncul jika opsi banyak).
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<SheetOption<T>> options,
  T? selected,
  String emptyMessage = 'Belum ada data.',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _OptionSheet<T>(title: title, options: options, selected: selected, emptyMessage: emptyMessage),
  );
}

class _OptionSheet<T> extends StatefulWidget {
  final String title;
  final List<SheetOption<T>> options;
  final T? selected;
  final String emptyMessage;
  const _OptionSheet({required this.title, required this.options, this.selected, required this.emptyMessage});

  @override
  State<_OptionSheet<T>> createState() => _OptionSheetState<T>();
}

class _OptionSheetState<T> extends State<_OptionSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((o) => _query.isEmpty || o.title.toLowerCase().contains(_query.toLowerCase()) || (o.subtitle ?? '').toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * 0.8),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            if (widget.options.length > 6)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  autofocus: false,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Cari…',
                    prefixIcon: Icon(Icons.search_rounded),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text(_query.isEmpty ? widget.emptyMessage : 'Tidak ditemukan.', style: const TextStyle(color: AppColors.inkSoft))),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final o = filtered[i];
                        final isSelected = o.value == widget.selected;
                        return ListTile(
                          enabled: o.enabled,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          tileColor: isSelected ? AppColors.primarySoft : null,
                          leading: o.leading,
                          title: Text(o.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: o.subtitle != null ? Text(o.subtitle!, style: const TextStyle(fontSize: 12)) : null,
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                              : (o.trailing != null
                                  ? Text(o.trailing!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: o.enabled ? AppColors.inkSoft : AppColors.muted))
                                  : null),
                          onTap: () => Navigator.pop(context, o.value),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}
