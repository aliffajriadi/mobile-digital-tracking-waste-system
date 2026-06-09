import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/constants/api_constants.dart';

class ProfileService {
  // Mengambil data profil yang tersimpan di lokal device
  Future<Map<String, String?>> getLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('user_name'),
      'email': prefs.getString('user_email') ?? prefs.getString('email'),
      'phone': prefs.getString('user_phone'),
      'nik': prefs.getString('user_nik'),
      'image': prefs.getString('user_profile_text'),
    };
  }

  // Mengirim pembaruan data profil ke API server
  Future<bool> updateRemoteProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final url = ApiConstants.updateProfile;

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
      },
    ).timeout(const Duration(seconds: 10));

    final responseData = json.decode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      // Jika server sukses merespon, update data lokal
      await prefs.setString('user_name', name.trim());
      if (prefs.containsKey('user_email')) {
        await prefs.setString('user_email', email.trim());
      } else {
        await prefs.setString('email', email.trim());
      }
      await prefs.setString('user_phone', phone.trim());
      return true;
    } else {
      throw responseData['message'] ?? 'Gagal memperbarui profil';
    }
  }
}