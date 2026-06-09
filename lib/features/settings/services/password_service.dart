import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/constants/api_constants.dart';

class PasswordService {
  Future<http.Response> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse(ApiConstants.changePassword),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    ).timeout(const Duration(seconds: 10));

    return response;
  }
}