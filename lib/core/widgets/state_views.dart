import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: AppColors.primary),
        if (message != null) ...[
          const SizedBox(height: 14),
          Text(message!, style: const TextStyle(color: AppColors.inkSoft)),
        ],
      ]),
    );
  }
}

class MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Color color;
  final Widget? action;

  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.color = AppColors.muted,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13, height: 1.5)),
          ],
          if (action != null) ...[const SizedBox(height: 18), action!],
        ]),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MessageView(
      icon: Icons.cloud_off_rounded,
      title: 'Gagal memuat data',
      message: message,
      color: AppColors.danger,
      action: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(160, 46)),
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Coba lagi'),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  const EmptyView({super.key, required this.icon, required this.title, this.message, this.action});

  @override
  Widget build(BuildContext context) =>
      MessageView(icon: icon, title: title, message: message, color: AppColors.primary, action: action);
}

/// Placeholder abu-abu saat memuat list.
class SkeletonList extends StatelessWidget {
  final int count;
  final double height;
  const SkeletonList({super.key, this.count = 5, this.height = 72});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        height: height,
        decoration: BoxDecoration(color: const Color(0xFFE9EEF2), borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
