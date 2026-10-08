import 'package:flutter/foundation.dart';

/// Sinyal sederhana agar halaman lain memuat ulang data setelah ada transaksi baru.
class AppEvents {
  AppEvents._();

  static final ValueNotifier<int> dataChanged = ValueNotifier<int>(0);

  static void notifyDataChanged() => dataChanged.value++;
}
