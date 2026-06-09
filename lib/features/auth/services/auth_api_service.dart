import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';

class AuthApiService {
  /// Fungsi untuk menembak API Login Laravel. 
  /// Mengembalikan Map berisi data jika sukses, atau melempar Exception jika gagal.
  Future<Map<String, dynamic>> postLogin(String nik, String password) async {
    final url = Uri.parse(ApiConstants.login);
    
    try {
      final response = await http.post(
        url,
        headers: {'Accept': 'application/json'},
        body: {'nik': nik, 'password': password},
      ).timeout(const Duration(seconds: 10)); // Mencegah loading selamanya jika server hang

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Login Gagal');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server. Pastikan API menyala.');
    }
  }
}