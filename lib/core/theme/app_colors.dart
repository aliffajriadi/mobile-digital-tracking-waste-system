import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF14A38B);
  static const primaryDark = Color(0xFF0E7F6C);
  static const primarySoft = Color(0xFFE3F6F2);

  static const ink = Color(0xFF1E293B);
  static const inkSoft = Color(0xFF475569);
  static const muted = Color(0xFF94A3B8);
  static const line = Color(0xFFE2E8F0);
  static const surface = Colors.white;
  static const background = Color(0xFFF4F7F9);

  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);

  // Warna per jenis transaksi (konsisten di seluruh aplikasi)
  static const masuk = Color(0xFF0EA5E9);
  static const olahan = Color(0xFF7C3AED);
  static const keluar = Color(0xFFEA580C);
  static const kendala = Color(0xFFE11D48);
}

/// Identitas visual tiap jenis transaksi.
enum TxType {
  masuk('Sampah Masuk', Icons.south_west_rounded, AppColors.masuk),
  olahan('Olahan', Icons.recycling_rounded, AppColors.olahan),
  keluar('Sampah Keluar', Icons.north_east_rounded, AppColors.keluar),
  kendala('Kendala', Icons.report_gmailerrorred_rounded, AppColors.kendala);

  final String label;
  final IconData icon;
  final Color color;
  const TxType(this.label, this.icon, this.color);

  static TxType fromLog(String type) => switch (type) {
        'input_masuk' => TxType.masuk,
        'input_keluar' => TxType.keluar,
        'olahan' => TxType.olahan,
        _ => TxType.kendala,
      };
}
