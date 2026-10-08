import 'dart:convert';
import 'dart:io';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/utils/formatters.dart';
import 'models.dart';

List<Map<String, dynamic>> _list(dynamic data) =>
    data is List ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];

/// Akses data API untuk semua fitur aplikasi PIC.
class Repo {
  Repo._();

  // ---------- Auth & Profil ----------
  static Future<Map<String, dynamic>> login(String nik, String password) =>
      ApiClient.post(ApiConstants.login, {'nik': nik, 'password': password});

  static Future<Map<String, dynamic>> me() async => Map<String, dynamic>.from((await ApiClient.get(ApiConstants.me))['user'] ?? {});

  static Future<void> logout() => ApiClient.post(ApiConstants.logout);

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? phone,
    File? photo,
  }) async {
    final res = await ApiClient.multipart(ApiConstants.updateProfile,
        fields: {'name': name, 'email': email, 'phone': phone ?? ''}, files: {'photo': photo});
    return Map<String, dynamic>.from(res['user'] ?? {});
  }

  static Future<String> changePassword(String oldPassword, String newPassword) async {
    final res = await ApiClient.post(ApiConstants.changePassword, {'old_password': oldPassword, 'new_password': newPassword});
    return (res['message'] ?? 'Kata sandi berhasil diperbarui.').toString();
  }

  // ---------- Dashboard ----------
  static Future<Map<String, dynamic>> dashboard() => ApiClient.get(ApiConstants.dashboardData);

  // ---------- Master data ----------
  static Future<List<WasteCategory>> categories() async =>
      _list((await ApiClient.get(ApiConstants.categories))['data']).map(WasteCategory.fromJson).toList();

  static Future<List<WasteSubCategory>> subCategories(int categoryId) async =>
      _list((await ApiClient.get('${ApiConstants.subCategories}/$categoryId'))['data']).map(WasteSubCategory.fromJson).toList();

  static Future<List<NamedItem>> sourceLocations() async =>
      _list((await ApiClient.get(ApiConstants.sourceLocations))['data']).map(NamedItem.fromJson).toList();

  static Future<List<ProcessedType>> processedTypes() async =>
      _list((await ApiClient.get(ApiConstants.processedWaste))['data']).map(ProcessedType.fromJson).toList();

  static Future<List<WasteOutMethod>> outMethods() async =>
      _list((await ApiClient.get(ApiConstants.wasteOutMethods))['data']).map(WasteOutMethod.fromJson).toList();

  static Future<List<NamedItem>> buyers() async =>
      _list((await ApiClient.get(ApiConstants.wasteBuyers))['data']).map(NamedItem.fromJson).toList();

  static Future<List<NamedItem>> destinations() async =>
      _list((await ApiClient.get(ApiConstants.wasteDestinations))['data']).map(NamedItem.fromJson).toList();

  static Future<List<NamedItem>> reportCategories() async =>
      _list((await ApiClient.get(ApiConstants.kategoriKendala))['data']).map(NamedItem.fromJson).toList();

  // ---------- Stok & notifikasi ----------
  static Future<List<StockItem>> stocks() async =>
      _list((await ApiClient.get(ApiConstants.wasteStocks))['data']).map(StockItem.fromJson).toList();

  static Future<List<B3Alert>> b3Alerts() async =>
      _list((await ApiClient.get(ApiConstants.wasteB3Notifications))['data']).map(B3Alert.fromJson).toList();

  // ---------- Transaksi ----------
  static Future<String> submitWasteEntry({
    required int subCategoryId,
    required int locationId,
    required double qty,
    required DateTime time,
    String? notes,
    File? photo,
  }) async {
    final res = await ApiClient.multipart(ApiConstants.wasteEntry, fields: {
      'id_waste_sub_category': '$subCategoryId',
      'id_source_location_waste': '$locationId',
      'measured_qty': '$qty',
      'notes': notes,
      'created_at': Fmt.apiDateTime(time),
    }, files: {
      'photo': photo
    });
    return (res['message'] ?? 'Data berhasil disimpan.').toString();
  }

  static Future<String> submitProcessed({
    required int processedId,
    required double qty,
    required DateTime time,
    required Map<int, double> rawMaterials,
    String? notes,
  }) async {
    final res = await ApiClient.post(ApiConstants.processedWasteData, {
      'id_processed_waste': processedId,
      'measured_qty': qty,
      'notes': notes,
      'created_at': Fmt.apiDateTime(time),
      'raw_materials': jsonEncode(rawMaterials.entries
          .map((e) => {'id_waste_sub_category': e.key, 'measured_qty': e.value})
          .toList()),
    });
    return (res['message'] ?? 'Data berhasil disimpan.').toString();
  }

  static Future<String> submitWasteOut({
    required int methodId,
    required Map<String, double> items,
    required DateTime time,
    int? destinationId,
    int? buyerId,
    double? revenue,
    String? notes,
    File? photo,
  }) async {
    final res = await ApiClient.multipart(ApiConstants.wasteOut, fields: {
      'id_waste_out_method': '$methodId',
      'id_waste_destination': destinationId?.toString(),
      'id_buyer': buyerId?.toString(),
      'total_revenue': revenue?.toString(),
      'notes': notes,
      'created_at': Fmt.apiDateTime(time),
      'items': jsonEncode(items.entries.map((e) => {'id_sub_category': e.key, 'quantity': e.value}).toList()),
    }, files: {
      'photo': photo
    });
    return (res['message'] ?? 'Data berhasil disimpan.').toString();
  }

  static Future<String> submitReport({
    required int categoryId,
    required String title,
    required String content,
    File? attachment,
  }) async {
    final res = await ApiClient.multipart(ApiConstants.laporanKendala, fields: {
      'id_category_report': '$categoryId',
      'title': title,
      'content': content,
    }, files: {
      'attachment': attachment
    });
    return (res['message'] ?? 'Laporan berhasil dikirim.').toString();
  }

  // ---------- Riwayat ----------
  static Future<({List<HistoryGroup> groups, int total})> history({String? search, String? type}) async {
    final res = await ApiClient.get(ApiConstants.riwayatLaporan, query: {'search': search, 'type': type});
    final data = res['data'];
    final groups = <HistoryGroup>[];
    if (data is Map) {
      data.forEach((date, items) {
        groups.add(HistoryGroup(date.toString(), _list(items).map(HistoryEntry.fromJson).toList()));
      });
    }
    return (groups: groups, total: int.tryParse(res['total']?.toString() ?? '') ?? groups.fold<int>(0, (s, g) => s + g.entries.length));
  }

  static Future<Map<String, dynamic>> entryDetail(int id) async =>
      Map<String, dynamic>.from((await ApiClient.get('${ApiConstants.laporanHarian}/$id'))['data'] ?? {});

  static Future<Map<String, dynamic>> outDetail(int id) async =>
      Map<String, dynamic>.from((await ApiClient.get('${ApiConstants.wasteOut}/$id'))['data'] ?? {});

  static Future<Map<String, dynamic>> processedDetail(int id) async =>
      Map<String, dynamic>.from((await ApiClient.get('${ApiConstants.processedWasteData}/$id'))['data'] ?? {});

  static Future<Map<String, dynamic>> reportDetail(int id) async =>
      Map<String, dynamic>.from((await ApiClient.get('${ApiConstants.laporanKendala}/$id'))['data'] ?? {});

  // ---------- IoT ----------
  static Future<String?> iotSession() async {
    final res = await ApiClient.get(ApiConstants.iotSession);
    return res['paired'] == true ? res['code']?.toString() : null;
  }

  static Future<String> iotPair(String code) async =>
      ((await ApiClient.post(ApiConstants.iotPair, {'code': code}))['message'] ?? 'Terhubung.').toString();

  static Future<String> iotUnpair(String code) async =>
      ((await ApiClient.post(ApiConstants.iotUnpair, {'code': code}))['message'] ?? 'Terputus.').toString();
}
