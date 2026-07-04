import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';

class AuthApiService {
  Future<Map<String, dynamic>> postLogin(String nik, String password) async {
    final url = Uri.parse(ApiConstants.login);

    try {
      final response = await http.post(
        url,
        headers: {'Accept': 'application/json'},
        body: {
          'nik': nik,
          'password': password,
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      }

      // Kirim pesan dari Laravel apa adanya
      throw Exception(data['message'] ?? 'Login gagal.');
    }

    on SocketException {
      throw Exception(
        'Tidak ada koneksi internet atau server tidak dapat dihubungi.',
      );
    }

    on http.ClientException {
      throw Exception(
        'Gagal terhubung ke server. Pastikan API menyala.',
      );
    }

    on FormatException {
      throw Exception(
        'Respon server tidak valid.',
      );
    }

    on Exception {
      rethrow;
    }
}
}