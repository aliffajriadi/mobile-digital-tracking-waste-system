import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_api_service.dart';
import '../models/user_model.dart';

class LoginController {
  final AuthApiService _apiService = AuthApiService();

  /// Fungsi mengeksekusi logika login dan menyimpan sesi user
  Future<UserModel> executeLogin(String nik, String password) async {
    // 1. Validasi Input Dasar
    if (nik.trim().isEmpty || password.isEmpty) {
      throw Exception('NIK dan Kata Sandi wajib diisi!');
    }

    // 2. Panggil API Service
    final responseData = await _apiService.postLogin(nik.trim(), password);

    // 3. Parsing data user menggunakan Model
    final user = UserModel.fromJson(responseData['user']);
    final token = responseData['token'];

    // 4. Simpan ke SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user_name', user.fullName);
    await prefs.setString('user_nik', user.nik);
    await prefs.setString('user_email', user.email);

    return user;
  }
}