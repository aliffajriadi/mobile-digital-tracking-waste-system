import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../theme/app_colors.dart';

enum FeedbackType { success, error, info }

class AppFeedback {
  AppFeedback._();

  static void snack(BuildContext context, String message, {FeedbackType type = FeedbackType.info}) {
    final (color, icon) = switch (type) {
      FeedbackType.success => (AppColors.success, Icons.check_circle_rounded),
      FeedbackType.error => (AppColors.danger, Icons.error_rounded),
      FeedbackType.info => (AppColors.ink, Icons.info_rounded),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: color,
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
      ));
  }

  static void success(BuildContext context, String message) => snack(context, message, type: FeedbackType.success);

  /// Tampilkan error dari API. Error validasi (bisa banyak pesan) ditampilkan sebagai dialog.
  static Future<void> error(BuildContext context, Object error, {String title = 'Gagal menyimpan'}) async {
    final message = error is ApiException ? error.fullMessage : 'Terjadi kesalahan tak terduga. Silakan coba lagi.';
    if (error is ApiException && (error.isValidation || message.contains('\n'))) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 32),
          title: Text(title),
          content: Text(message, style: const TextStyle(height: 1.5)),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti'))],
        ),
      );
      return;
    }
    if (context.mounted) snack(context, message, type: FeedbackType.error);
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Ya',
    String cancelLabel = 'Batal',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancelLabel)),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: destructive ? AppColors.danger : AppColors.primary,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
