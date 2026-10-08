import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan sesi login & preferensi lokal.
class SessionStore {
  SessionStore._();

  static const _kToken = 'token';
  static const _kUserId = 'user_id';
  static const _kName = 'user_name';
  static const _kNik = 'user_nik';
  static const _kEmail = 'user_email';
  static const _kPhone = 'user_phone';
  static const _kPhoto = 'user_photo';
  static const _kIotCode = 'iot_paired_code';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<String?> token() async {
    final t = (await _prefs).getString(_kToken);
    return (t == null || t.isEmpty) ? null : t;
  }

  static Future<void> saveLogin(String token, Map<String, dynamic> user) async {
    final p = await _prefs;
    await p.setString(_kToken, token);
    await saveUser(user);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final p = await _prefs;
    if (user['id'] != null) await p.setInt(_kUserId, int.tryParse(user['id'].toString()) ?? 0);
    await p.setString(_kName, (user['full_name'] ?? '').toString());
    await p.setString(_kNik, (user['nik'] ?? '').toString());
    await p.setString(_kEmail, (user['email'] ?? '').toString());
    await p.setString(_kPhone, (user['phone'] ?? '').toString());
    await p.setString(_kPhoto, (user['photo_url'] ?? user['photo'] ?? '').toString());
  }

  static Future<Map<String, String>> user() async {
    final p = await _prefs;
    return {
      'id': (p.getInt(_kUserId) ?? 0).toString(),
      'full_name': p.getString(_kName) ?? '',
      'nik': p.getString(_kNik) ?? '',
      'email': p.getString(_kEmail) ?? '',
      'phone': p.getString(_kPhone) ?? '',
      'photo': p.getString(_kPhoto) ?? '',
    };
  }

  static Future<String?> iotCode() async => (await _prefs).getString(_kIotCode);

  static Future<void> setIotCode(String? code) async {
    final p = await _prefs;
    if (code == null || code.isEmpty) {
      await p.remove(_kIotCode);
    } else {
      await p.setString(_kIotCode, code);
    }
  }

  static Future<void> clear() async => (await _prefs).clear();
}
