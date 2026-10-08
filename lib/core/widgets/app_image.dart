import 'package:flutter/material.dart';

import '../constants/api_constants.dart';
import '../theme/app_colors.dart';

/// Gambar dari server dengan placeholder & fallback ikon jika gagal dimuat.
class AppNetworkImage extends StatelessWidget {
  final dynamic url;
  final double size;
  final double radius;
  final IconData fallbackIcon;
  final Color color;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.size = 52,
    this.radius = 14,
    this.fallbackIcon = Icons.image_outlined,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConstants.fileUrl(url);
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(radius)),
      child: Icon(fallbackIcon, color: color, size: size * 0.5),
    );
    if (resolved == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        resolved,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (ctx, child, progress) => progress == null
            ? child
            : Container(width: size, height: size, color: const Color(0xFFE9EEF2)),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String name;
  final String? photo;
  final double size;
  const UserAvatar({super.key, required this.name, this.photo, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((p) => p[0].toUpperCase()).join();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Text(initials, style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: size * 0.36)),
    );
    final url = ApiConstants.fileUrl(photo);
    if (url == null) return fallback;
    return ClipOval(
      child: Image.network(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback),
    );
  }
}
