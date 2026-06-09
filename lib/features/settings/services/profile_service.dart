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
    String? imagePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final url = ApiConstants.updateProfile;

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['name'] = name.trim();
    request.fields['email'] = email.trim();
    request.fields['phone'] = phone.trim();

    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('photo', imagePath));
    }

    final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
    final response = await http.Response.fromStream(streamedResponse);
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
      
      if (responseData['user'] != null && responseData['user']['photo'] != null) {
        await prefs.setString('user_profile_text', responseData['user']['photo']);
      }
      return true;
    } else {
      throw responseData['message'] ?? 'Gagal memperbarui profil';
    }
  }
}