import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';

class NotificationService {
  Future<List<dynamic>> fetchWasteB3Notifications() async {
    final response = await http.get(Uri.parse(ApiConstants.wasteB3Notifications));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    } else {
      final errorData = json.decode(response.body);
      throw errorData['message'] ?? 'Gagal memuat data (Status: ${response.statusCode})';
    }
  }
}