import 'package:intl/intl.dart';

class Fmt {
  Fmt._();

  static final _qty = NumberFormat('#,##0.##', 'id_ID');
  static final _rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  /// 1250.5 -> "1.250,5"
  static String qty(num? value) => _qty.format(value ?? 0);

  static String qtyUnit(num? value, String? unit) => '${qty(value)} ${unit == null || unit.isEmpty ? 'kg' : unit}';

  static String rupiah(num? value) => _rupiah.format(value ?? 0);

  /// Terima "1,5" maupun "1.5" (keyboard HP Indonesia sering memakai koma).
  static double? parseDecimal(String? input) {
    if (input == null) return null;
    final cleaned = input.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  static double toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// Format yang diterima server Laravel.
  static String apiDateTime(DateTime dt) => DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);

  static String dateTime(DateTime dt) => DateFormat('EEE, d MMM yyyy • HH:mm', 'id_ID').format(dt);

  static String date(DateTime dt) => DateFormat('d MMMM yyyy', 'id_ID').format(dt);

  static String time(DateTime dt) => DateFormat('HH:mm', 'id_ID').format(dt);

  static String greeting([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    final result = parts.map((p) => p[0].toUpperCase()).join();
    return result.isEmpty ? '?' : result;
  }
}
