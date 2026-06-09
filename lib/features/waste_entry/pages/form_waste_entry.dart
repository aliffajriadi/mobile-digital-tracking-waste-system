import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/constants/api_constants.dart'; 

class InputSampahPage extends StatefulWidget {
  // Menerima data map sub-kategori dinamis dari halaman sebelumnya
  final Map<String, dynamic> selectedSubCategory;

  const InputSampahPage({super.key, required this.selectedSubCategory});

  @override
  State<InputSampahPage> createState() => _InputSampahPageState();
}

class _InputSampahPageState extends State<InputSampahPage> {
  final _kuantitasController = TextEditingController();
  final _catatanController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _sumberLokasiList = [];
  Map<String, dynamic>? _selectedSumberLocation;
  
  DateTime _waktuTerpilih = DateTime.now();
  File? _buktiFoto;
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoadingLocations = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchSourceLocations();
  }

  @override
  void dispose() {
    _kuantitasController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  // --- GET DATA SUMBER LOKASI DARI API ---
  Future<void> _fetchSourceLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(ApiConstants.sourceLocations),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (resData['success'] == true) {
          setState(() {
            _sumberLokasiList = resData['data'];
            _isLoadingLocations = false;
          });
        }
      } else {
        setState(() => _isLoadingLocations = false);
      }
    } catch (e) {
      debugPrint("Gagal mengambil data lokasi: $e");
      setState(() => _isLoadingLocations = false);
    }
  }

  // --- AMBIL FOTO BUKTI ---
  Future<void> _ambilFotoBukti() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60, // Kompresi gambar agar hemat bandwidth server
      );

      if (image != null) {
        setState(() {
          _buktiFoto = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil foto: $e");
    }
  }

  // --- PICKER TANGGAL & WAKTU ---
  Future<void> _pilihWaktu(BuildContext context) async {
    final DateTime? tanggalPicked = await showDatePicker(
      context: context,
      initialDate: _waktuTerpilih,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
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

  // --- SIMPAN DATA (POST MULTIPART TO LARAVEL) ---
  Future<void> _simpanDataLaporan() async {
    // Validasi inputan wajib
    if (_selectedSumberLocation == null) {
      _showSnackbar("Silakan pilih sumber lokasi sampah terlebih dahulu!");
      return;
    }
    if (_kuantitasController.text.isEmpty) {
      _showSnackbar("Kuantitas data tidak boleh kosong!");
      return;
    }
    if (_buktiFoto == null) {
      _showSnackbar("Wajib melampirkan foto bukti sampah!");
      return;
    }

    // Biar user tidak bisa pencet tombol simpan berkali-kali saat proses kirim
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token') ?? '';

      var uri = Uri.parse(ApiConstants.wasteEntry); 
      var request = http.MultipartRequest('POST', uri);

      // Header Token Authentication
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Data Form Fields Text (Ubah koma ke titik jika user input desimal pakai koma)
      String kuantitas = _kuantitasController.text.replaceAll(',', '.');

      request.fields['id_waste_sub_category'] = widget.selectedSubCategory['id'].toString();
      request.fields['id_source_location_waste'] = _selectedSumberLocation!['id'].toString();
      request.fields['measured_qty'] = kuantitas;
      request.fields['notes'] = _catatanController.text;
      request.fields['created_at'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(_waktuTerpilih);

      // Lampirkan File Gambar Bukti Foto
      request.files.add(await http.MultipartFile.fromPath(
        'photo', 
        _buktiFoto!.path,
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackbar("Data transaksi sampah berhasil disimpan!", backgroundColor: Colors.green);
        
        // Kasih delay 1 detik biar snackbar terbaca sebelum halaman ditutup
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context, true); // Kembali dan trigger refresh
          }
        });
      } else {
        final errorLog = json.decode(response.body);
        _showSnackbar("Gagal menyimpan: ${errorLog['message'] ?? response.statusCode}");
      }
    } catch (e) {
      _showSnackbar("Terjadi kesalahan jaringan. Gagal terhubung ke server.");
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackbar(String msg, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: backgroundColor));
  }

  // --- MODAL DIALOG DROP-DOWN STYLISH UNTUK SUMBER LOKASI ---
  void _showSumberLokasiBottomSheet() {
    if (_isLoadingLocations) {
      _showSnackbar("Sedang memuat data lokasi, tunggu sebentar...", backgroundColor: Colors.blue);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pilih Sumber Sampah",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF264653)),
              ),
              const Divider(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _sumberLokasiList.length,
                  itemBuilder: (context, index) {
                    final lokasi = _sumberLokasiList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black12)
                      ),
                      child: ListTile(
                        title: Text(lokasi['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF14A38B)),
                        onTap: () {
                          setState(() => _selectedSumberLocation = lokasi);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);
    const darkBlueColor = Color(0xFF264653);
    const bgLightColor = Color(0xFFF4F7F9);

    // Ambil variabel dari objek data halaman sebelumnya
    var subKat = widget.selectedSubCategory;
    String subKatName = subKat['name'] ?? 'Jenis Sampah';
    
    // Satuan dinamis: cek relasi unit_measured jika ada, default ke 'Kg'
    String unitSymbol = "Kg";
    if (subKat['unit_measured'] != null) {
      unitSymbol = subKat['unit_measured']['symbol'] ?? 'Kg';
    }

    // Pengecekan data B3 khusus (Kondisional UI)
    bool isB3 = subKat['id_waste_b3_detail'] != null || subKat['id_waste_category'].toString() == '3'; // Asumsikan semua sub-kategori bisa jadi B3, nanti cek di dalamnya
    String? b3Code;
    if (isB3 && subKat['b3_detail'] != null && subKat['b3_detail'] is Map) {
      b3Code = subKat['b3_detail']['waste_code']?.toString();
    }

    return Scaffold(
      backgroundColor: bgLightColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Input Sampah Masuk', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      
      // 1. BODY: KHUSUS FORM YANG BISA DI-SCROLL
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 12),
                  Text("Menyimpan data entry ke server...", style: TextStyle(color: darkBlueColor, fontWeight: FontWeight.w600))
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. INFO JENIS SAMPAH TERPILIH
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(color: const Color(0xFFE9F5F3), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.restore_from_trash_rounded, color: primaryColor, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(subKatName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBlueColor)),
                                const SizedBox(height: 4),
                                
                                // CHIP KHUSUS B3
                                if (isB3)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.red.shade200)),
                                    child: Text(
                                      "Kategori Bahaya B3: ${b3Code ?? 'Terdata'}",
                                      style: TextStyle(color: Colors.red.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. WAKTU TRANSAKSI
                    _buildLabel("Waktu Pengisian / Transaksi"),
                    InkWell(
                      onTap: () => _pilihWaktu(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: primaryColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(DateFormat('dd MMM yyyy, HH:mm').format(_waktuTerpilih) + " WIB", style: const TextStyle(fontWeight: FontWeight.w600, color: darkBlueColor))),
                            const Icon(Icons.edit_calendar_rounded, color: Colors.grey, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. SELEKSI SUMBER LOKASI
                    _buildLabel("Sumber Lokasi Sampah"),
                    InkWell(
                      onTap: _showSumberLokasiBottomSheet,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: primaryColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedSumberLocation == null ? "Pilih lokasi sumber sampah..." : _selectedSumberLocation!['name'],
                                style: TextStyle(fontWeight: FontWeight.w600, color: _selectedSumberLocation == null ? Colors.grey : darkBlueColor),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down_circle_rounded, color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. KUANTITAS BERDASARKAN SATUAN
                    _buildLabel("Kuantitas Data Sampah"),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                            child: TextField(
                              controller: _kuantitasController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: "0.00",
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                suffixText: unitSymbol,
                                suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF14A38B)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Material(
                          color: const Color(0xFF14A38B),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => _showSnackbar("Menghubungkan ke timbangan..."),
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(15),
                              child: Icon(Icons.scale_rounded, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 5. UPLOAD BUKTI FOTO
                    _buildLabel("Upload Bukti Foto Fisik"),
                    InkWell(
                      onTap: _ambilFotoBukti,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                        child: _buktiFoto != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_buktiFoto!, fit: BoxFit.cover, width: double.infinity),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_rounded, size: 44, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text("Buka Kamera PIC", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6. CATATAN PIC
                    _buildLabel("Catatan Lapangan PIC (Opsional)"),
                    Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                      child: TextField(
                        controller: _catatanController,
                        maxLines: 3,
                        decoration: const InputDecoration(hintText: "Tulis kondisi sampah atau catatan di sini...", border: InputBorder.none, contentPadding: EdgeInsets.all(16)),
                      ),
                    ),
                    const SizedBox(height: 10), 
                    // Jarak penutup form aman agar isi scroll tidak terpotong ke bawah
                  ],
                ),
              ),
            ),

      // 2. BOTTOM NAV BAR: TOMBOL NETAP DI BAWAH & AMAN DARI NAVIGASI HP ASLI
      bottomNavigationBar: _isSubmitting 
          ? null 
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16, top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Batal", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _simpanDataLaporan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Simpan Data", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF264653))),
    );
  }
}