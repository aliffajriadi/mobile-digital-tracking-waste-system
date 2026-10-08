import '../core/utils/formatters.dart';

class NamedItem {
  final int id;
  final String name;
  final String? description;
  final String? photo;
  final Map<String, dynamic> raw;

  const NamedItem({required this.id, required this.name, this.description, this.photo, this.raw = const {}});

  factory NamedItem.fromJson(Map<String, dynamic> j) => NamedItem(
        id: int.tryParse(j['id'].toString()) ?? 0,
        name: (j['name'] ?? '-').toString(),
        description: j['description']?.toString() ?? j['location']?.toString() ?? j['address']?.toString(),
        photo: (j['photo_url'] ?? j['photo'])?.toString(),
        raw: j,
      );

  @override
  bool operator ==(Object other) => other is NamedItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class WasteCategory extends NamedItem {
  final int subCount;
  const WasteCategory({required super.id, required super.name, super.description, super.photo, this.subCount = 0});

  factory WasteCategory.fromJson(Map<String, dynamic> j) => WasteCategory(
        id: int.tryParse(j['id'].toString()) ?? 0,
        name: (j['name'] ?? '-').toString(),
        description: j['description']?.toString(),
        photo: (j['photo_url'] ?? j['photo'])?.toString(),
        subCount: int.tryParse(j['sub_categories_count']?.toString() ?? '') ?? 0,
      );
}

class WasteSubCategory {
  final int id;
  final String name;
  final String? description;
  final String? photo;
  final String unit;
  final double stock;
  final double defaultQty;
  final String? b3Code;
  final int? b3RetentionDays;

  const WasteSubCategory({
    required this.id,
    required this.name,
    this.description,
    this.photo,
    this.unit = 'kg',
    this.stock = 0,
    this.defaultQty = 0,
    this.b3Code,
    this.b3RetentionDays,
  });

  bool get isB3 => b3Code != null;

  factory WasteSubCategory.fromJson(Map<String, dynamic> j) {
    final unit = j['unit'] ?? (j['unit_measured'] is Map ? j['unit_measured']['symbol'] : null);
    final b3 = j['b3_detail'] is Map ? j['b3_detail'] as Map : null;
    return WasteSubCategory(
      id: int.tryParse(j['id'].toString()) ?? 0,
      name: (j['name'] ?? '-').toString(),
      description: j['description']?.toString(),
      photo: (j['photo_url'] ?? j['photo'])?.toString(),
      unit: (unit ?? 'kg').toString(),
      stock: Fmt.toDouble(j['stock']),
      defaultQty: Fmt.toDouble(j['default_measured_qty']),
      b3Code: b3?['waste_code']?.toString(),
      b3RetentionDays: int.tryParse(b3?['retention_period_day']?.toString() ?? ''),
    );
  }
}

/// Satu baris stok gudang (sampah mentah atau hasil olahan).
class StockItem {
  /// Id dari server: angka untuk sampah mentah, `p_<id>` untuk hasil olahan.
  final String key;
  final String name;
  final String category;
  final int? categoryId;
  final double stock;
  final String unit;
  final bool isProcessed;
  final bool isB3;
  final String? b3Code;
  final String? photo;

  const StockItem({
    required this.key,
    required this.name,
    required this.category,
    this.categoryId,
    required this.stock,
    required this.unit,
    required this.isProcessed,
    this.isB3 = false,
    this.b3Code,
    this.photo,
  });

  int get rawId => int.tryParse(key.replaceFirst('p_', '')) ?? 0;

  factory StockItem.fromJson(Map<String, dynamic> j) {
    final key = j['id'].toString();
    return StockItem(
      key: key,
      name: (j['name'] ?? j['kategori'] ?? '-').toString(),
      category: (j['category'] ?? j['jenis_kategori'] ?? 'Umum').toString(),
      categoryId: int.tryParse(j['id_category']?.toString() ?? ''),
      stock: Fmt.toDouble(j['stock']),
      unit: (j['unit'] ?? 'kg').toString(),
      isProcessed: j['type'] == 'processed' || key.startsWith('p_'),
      isB3: j['is_b3'] == true,
      b3Code: j['b3_code']?.toString(),
      photo: j['photo_url']?.toString(),
    );
  }
}

class WasteOutMethod extends NamedItem {
  final bool isSelling;
  const WasteOutMethod({required super.id, required super.name, super.description, super.photo, this.isSelling = false});

  factory WasteOutMethod.fromJson(Map<String, dynamic> j) {
    final name = (j['name'] ?? '-').toString();
    return WasteOutMethod(
      id: int.tryParse(j['id'].toString()) ?? 0,
      name: name,
      description: j['description']?.toString(),
      photo: (j['photo_url'] ?? j['photo'])?.toString(),
      // Server lama belum punya flag is_selling: tebak dari nama
      isSelling: j['is_selling'] == true || (j['is_selling'] == null && name.toLowerCase().contains('jual')),
    );
  }
}

class ProcessedType extends NamedItem {
  final String unit;
  final double stock;
  const ProcessedType({required super.id, required super.name, super.description, super.photo, this.unit = 'kg', this.stock = 0});

  factory ProcessedType.fromJson(Map<String, dynamic> j) => ProcessedType(
        id: int.tryParse(j['id'].toString()) ?? 0,
        name: (j['name'] ?? '-').toString(),
        description: j['description']?.toString(),
        photo: (j['photo_url'] ?? j['photo'])?.toString(),
        unit: (j['unit'] ?? 'kg').toString(),
        stock: Fmt.toDouble(j['stock']),
      );
}

class B3Alert {
  final String code;
  final String name;
  final int daysLeft;
  final int retentionDays;
  final double stock;
  final String unit;
  final DateTime? since;
  final String status;

  const B3Alert({
    required this.code,
    required this.name,
    required this.daysLeft,
    required this.retentionDays,
    required this.stock,
    required this.unit,
    required this.since,
    required this.status,
  });

  factory B3Alert.fromJson(Map<String, dynamic> j) => B3Alert(
        code: (j['waste_code'] ?? '-').toString(),
        name: (j['waste_name'] ?? '-').toString(),
        daysLeft: int.tryParse(j['sisa_hari'].toString()) ?? 0,
        retentionDays: int.tryParse(j['retention_period_day'].toString()) ?? 0,
        stock: Fmt.toDouble(j['stock']),
        unit: (j['unit'] ?? 'kg').toString(),
        since: DateTime.tryParse(j['created_at']?.toString() ?? ''),
        status: (j['status'] ?? ((int.tryParse(j['sisa_hari'].toString()) ?? 0) < 0 ? 'expired' : 'warning')).toString(),
      );
}

class HistoryEntry {
  final int id;
  final String type;
  final String title;
  final String? subtitle;
  final String time;
  final String amount;

  const HistoryEntry({required this.id, required this.type, required this.title, this.subtitle, required this.time, required this.amount});

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: int.tryParse(j['id'].toString()) ?? 0,
        type: (j['type_log'] ?? '').toString(),
        title: (j['title'] ?? '-').toString(),
        subtitle: j['subtitle']?.toString(),
        time: (j['time'] ?? '-').toString(),
        amount: (j['amount'] ?? '').toString(),
      );
}

class HistoryGroup {
  final String date;
  final List<HistoryEntry> entries;
  const HistoryGroup(this.date, this.entries);
}
