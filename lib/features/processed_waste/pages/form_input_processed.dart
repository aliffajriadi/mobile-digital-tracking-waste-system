import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/constants/api_constants.dart'; // Sesuaikan path constants projectmu

class FormInputOlahanPage extends StatefulWidget {
  final Map<String, dynamic> selectedOlahan; // Menerima data olahan dari halaman sebelumnya

  const FormInputOlahanPage({super.key, required this.selectedOlahan});

  @override
  State<FormInputOlahanPage> createState() => _FormInputOlahanPageState();
}

class _FormInputOlahanPageState extends State<FormInputOlahanPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _kuantitasController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  DateTime _waktuTerpilih = DateTime.now();
  bool _isSaving = false;

  // --- FUNGSI TANGGAL & WAKTU ---
  Future<void> _pilihWaktu(BuildContext context) async {
    final DateTime? tanggalPicked = await showDatePicker(
      context: context,
      initialDate: _waktuTerpilih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (tanggalPicked != null) {
      final TimeOfDay? waktuPicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_waktuTerpilih),
      );
      if (waktuPicked != null) {
        setState(() {
          _waktuTerpilih = DateTime(
            tanggalPicked.year,
            tanggalPicked.month,
            tanggalPicked.day,
            waktuPicked.hour,
            waktuPicked.minute,
          );
        });
      }
    }
  }

  // --- FUNGSI KIRIM DATA (POST) KE LARAVEL ---
  Future<void> _simpanDataOlahan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // 1. Ambil token login PIC dari Shared Preferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // 2. Siapkan Endpoint URL (Gunakan variabel global)
      var url = Uri.parse('${ApiConstants.baseUrl}/processed-waste-data');

      String kuantitas = _kuantitasController.text.replaceAll(',', '.');

      // 3. Format tanggal ke format standar database MySQL (YYYY-MM-DD HH:MM:SS)
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(_waktuTerpilih);

      // 4. Lakukan Request POST JSON biasa (karena tidak ada upload file gambar)
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token', // Mengirim identitas PIC lewat token login
        },
        body: json.encode({
          'id_processed_waste': widget.selectedOlahan['id'].toString(),
          'measured_qty': _kuantitasController.text,
          'notes': _catatanController.text.isEmpty ? null : _catatanController.text,
          'created_at': formattedDate,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 || responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Data olahan berhasil disimpan!')),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true); // Balik ke halaman sebelumnya & bawa sinyal true (untuk refresh)
        });
      } else {
        String pesanError = responseData['message'] ?? 'Gagal menyimpan data';
        _showErrorDialog(pesanError);
      }
    } catch (e) {
      _showErrorDialog('Terjadi masalah koneksi atau error system: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gagal Menyimpan'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);
    
    // Mengambil simbol satuan dari data relasi database, default ke 'kg' jika null
    String unitSymbol = 'kg';
    if (widget.selectedOlahan['unit_measured'] != null) {
      unitSymbol = widget.selectedOlahan['unit_measured']['symbol'] ?? 'kg';
    } else if (widget.selectedOlahan['unit'] != null) {
      unitSymbol = widget.selectedOlahan['unit']['symbol'] ?? 'kg';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text('Input ${widget.selectedOlahan['name'] ?? 'Olahan'}', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CARD INFO JENIS OLAHAN ---
              Card(
                elevation: 0,
                color: primaryColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: primaryColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.selectedOlahan['name'] ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF264653)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.selectedOlahan['description'] ?? 'Hasil pengolahan sampah.',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- INPUT KUANTITAS ---
              const Text('Kuantitas Hasil Olahan', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF264653))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _kuantitasController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.00',
                  suffixText: unitSymbol, // Mengambil otomatis sesuai database (misal: kg)
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Kuantitas tidak boleh kosong';
                  if (double.tryParse(val) == null) return 'Masukkan angka yang valid';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- INPUT WAKTU / TANGGAL ---
              const Text('Waktu Pengolahan Selesai', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF264653))),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _pilihWaktu(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd MMMM yyyy, HH:mm').format(_waktuTerpilih), style: const TextStyle(fontSize: 15)),
                      const Icon(Icons.calendar_month, color: primaryColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- INPUT CATATAN ---
              const Text('Catatan Tambahan (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF264653))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _catatanController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Masukkan catatan jika ada...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 40),

              // --- TOMBOL SIMPAN ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSaving ? null : _simpanDataOlahan,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Data Olahan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}