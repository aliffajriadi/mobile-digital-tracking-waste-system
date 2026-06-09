import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/constants/api_constants.dart';

class HistoryService {
  Future<Map<String, dynamic>> fetchRiwayatLaporan({
    String searchQuery = "",
    int? selectedCategoryId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    String url = "${ApiConstants.riwayatLaporan}?search=$searchQuery";
    if (selectedCategoryId != null) {
      url += "&type=$selectedCategoryId";
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw "Gagal memuat riwayat (Status: ${response.statusCode})";
    }
  }
}