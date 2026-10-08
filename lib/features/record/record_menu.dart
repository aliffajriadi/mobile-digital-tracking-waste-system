import 'package:flutter/material.dart';

import '../../core/app_events.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_feedback.dart';
import '../entry/entry_category_page.dart';
import '../out/out_form_page.dart';
import '../processed/processed_form_page.dart';
import '../report/report_form_page.dart';

/// Buka halaman form, lalu beri tahu halaman lain jika ada data baru tersimpan.
Future<void> openRecordFlow(BuildContext context, Widget page) async {
  final saved = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => page));
  if (saved != null && context.mounted) {
    AppEvents.notifyDataChanged();
    AppFeedback.success(context, saved);
  }
}

Future<void> showRecordMenu(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      Widget tile(TxType type, String title, String subtitle, Widget page) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: type.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(type.icon, color: type.color),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          onTap: () {
            Navigator.pop(sheetContext);
            openRecordFlow(context, page);
          },
        );
      }

      return SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Catat aktivitas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          tile(TxType.masuk, 'Sampah Masuk', 'Timbang sampah yang baru tiba', const EntryCategoryPage()),
          tile(TxType.olahan, 'Hasil Olahan', 'Kompos, pupuk cair, kerajinan, dll.', const ProcessedFormPage()),
          tile(TxType.keluar, 'Sampah Keluar', 'Dikirim ke TPA, dijual, atau diserahkan', const OutFormPage()),
          tile(TxType.kendala, 'Laporan Kendala', 'Masalah operasional di lapangan', const ReportFormPage()),
          const SizedBox(height: 12),
        ]),
      );
    },
  );
}
