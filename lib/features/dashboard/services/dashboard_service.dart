import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_data.dart';
import '../../../core/constants/api_constants.dart';

class DashboardService {
  Future<DashboardData> getDashboardData() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse(ApiConstants.dashboardData),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final json = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data dashboard');
    }

    if (json['success'] != true) {
      throw Exception(json['message']);
    }

    return DashboardData.fromJson(json);
  }
}