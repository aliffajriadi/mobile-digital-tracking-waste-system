import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/constants/api_constants.dart';

class IotPairingPage extends StatefulWidget {
  const IotPairingPage({super.key});

  @override
  State<IotPairingPage> createState() => _IotPairingPageState();
}

class _IotPairingPageState extends State<IotPairingPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isConnecting = false;
  bool _isConnected = false;

  // Kunci SharedPreferences untuk menyimpan status sesi IoT
  static const _prefKeyCode = 'iot_paired_code';

  @override
  void initState() {
    super.initState();
    _loadSavedSession();
  }

  // Saat halaman dibuka, cek apakah ada sesi yang sudah tersimpan sebelumnya
  Future<void> _loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefKeyCode);
    if (savedCode != null && savedCode.isNotEmpty && mounted) {
      setState(() {
        _codeController.text = savedCode;
        _isConnected = true;
      });
    }
  }

  void _handlePairing() async {
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan kode alat terlebih dahulu!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isConnecting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final userId = prefs.getInt('user_id') ?? 0;

      if (userId == 0) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sesi Anda tidak valid. Silakan Logout dan Login kembali."), backgroundColor: Colors.red),
        );
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.iotPair),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'code': _codeController.text,
          'id_user': userId,
        }),
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        setState(() => _isConnecting = false);

        if (response.statusCode == 200 && data['success'] == true) {
          // Simpan kode ke SharedPreferences agar status tidak hilang saat navigasi
          await prefs.setString(_prefKeyCode, _codeController.text);
          setState(() => _isConnected = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Berhasil terhubung ke perangkat IoT!"), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Gagal menghubungkan alat"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terjadi kesalahan koneksi"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse(ApiConstants.iotUnpair),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'code': _codeController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Berhasil logout dari perangkat."), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Gagal logout dari perangkat."), backgroundColor: Colors.orange),
          );
        }

        // Hapus sesi dari SharedPreferences & reset UI
        await prefs.remove(_prefKeyCode);
        setState(() {
          _isConnected = false;
          _codeController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terjadi kesalahan jaringan saat logout."), backgroundColor: Colors.red),
        );
        // Tetap reset state secara lokal jika network error
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_prefKeyCode);
        setState(() {
          _isConnected = false;
          _codeController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: const Text("Integrasi IoT", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isConnected ? _buildConnectedState(primaryColor) : _buildPairingState(primaryColor),
      ),
    );
  }

  Widget _buildPairingState(Color primaryColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.settings_input_antenna, size: 80, color: primaryColor),
        const SizedBox(height: 30),
        const Text(
          "Masukkan Kode Alat",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF264653)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _codeController,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: "Contoh: A7B2",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isConnecting ? null : _handlePairing,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isConnecting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("HUBUNGKAN ALAT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedState(Color primaryColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 100, color: Colors.green),
        const SizedBox(height: 30),
        const Text(
          "Status: Sudah Terhubung",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF264653)),
        ),
        const SizedBox(height: 10),
        Text(
          "Perangkat ID: ${_codeController.text}",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text("Logout dari Perangkat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}