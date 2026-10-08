import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../session/session_store.dart';
import 'api_exception.dart';

/// Satu-satunya pintu untuk memanggil API Laravel.
/// Menangani token, timeout, parsing JSON, pesan error, dan sesi kedaluwarsa (401).
class ApiClient {
  ApiClient._();

  /// Bisa diganti di test dengan MockClient.
  static http.Client client = http.Client();

  static const Duration _timeout = Duration(seconds: 20);
  static const Duration _uploadTimeout = Duration(seconds: 60);

  /// Dipanggil sekali saat token ditolak server (akun dinonaktifkan / token dicabut).
  static Future<void> Function(String message)? onUnauthorized;
  static bool _handlingUnauthorized = false;

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await SessionStore.token();
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> get(String url, {Map<String, String?>? query}) {
    final params = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.isNotEmpty) params[k] = v;
    });
    final uri = Uri.parse(url).replace(queryParameters: params.isEmpty ? null : params);
    return _send(() async => client.get(uri, headers: await _headers()));
  }

  static Future<Map<String, dynamic>> post(String url, [Map<String, dynamic>? body]) {
    return _send(() async => client.post(
          Uri.parse(url),
          headers: await _headers(json: true),
          body: jsonEncode(body ?? {}),
        ));
  }

  /// Kirim form multipart (dengan file opsional). Nilai null pada [fields] tidak dikirim.
  static Future<Map<String, dynamic>> multipart(
    String url, {
    required Map<String, String?> fields,
    Map<String, File?> files = const {},
  }) {
    return _send(() async {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(await _headers());
      fields.forEach((k, v) {
        if (v != null) request.fields[k] = v;
      });
      for (final entry in files.entries) {
        if (entry.value != null) {
          request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value!.path));
        }
      }
      final streamed = await client.send(request).timeout(_uploadTimeout);
      return http.Response.fromStream(streamed);
    }, timeout: _uploadTimeout);
  }

  static Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() call, {
    Duration timeout = _timeout,
  }) async {
    http.Response response;
    try {
      response = await call().timeout(timeout);
    } on SocketException {
      throw const ApiException('Tidak ada koneksi internet. Periksa jaringan Anda lalu coba lagi.');
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons. Coba lagi beberapa saat lagi.');
    } on http.ClientException {
      throw const ApiException('Gagal terhubung ke server. Coba lagi beberapa saat lagi.');
    } on HandshakeException {
      throw const ApiException('Koneksi aman ke server gagal. Periksa jaringan Anda.');
    }

    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(response.body);
      data = decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    } on FormatException {
      if (response.statusCode >= 500) {
        throw ApiException('Terjadi gangguan pada server (${response.statusCode}).', statusCode: response.statusCode);
      }
      throw ApiException('Respons server tidak valid (${response.statusCode}).', statusCode: response.statusCode);
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300 && data['success'] != false;
    if (ok) return data;

    final message = (data['message'] ?? 'Terjadi kesalahan (${response.statusCode}).').toString();

    if (response.statusCode == 401) {
      await _handleUnauthorized(message);
      throw ApiException(message, statusCode: 401);
    }

    final errors = <String, List<String>>{};
    if (data['errors'] is Map) {
      (data['errors'] as Map).forEach((k, v) {
        errors[k.toString()] = v is List ? v.map((e) => e.toString()).toList() : [v.toString()];
      });
    }

    throw ApiException(message, statusCode: response.statusCode, errors: errors);
  }

  static Future<void> _handleUnauthorized(String message) async {
    if (_handlingUnauthorized) return;
    final hadToken = await SessionStore.token() != null;
    if (!hadToken) return; // mis. salah password saat login, bukan sesi kedaluwarsa
    _handlingUnauthorized = true;
    try {
      await SessionStore.clear();
      await onUnauthorized?.call(message);
    } finally {
      _handlingUnauthorized = false;
    }
  }
}
