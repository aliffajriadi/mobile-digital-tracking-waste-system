import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

class LaporanKendalaPage extends StatefulWidget {
  const LaporanKendalaPage({super.key});

  @override
  State<LaporanKendalaPage> createState() => _LaporanKendalaPageState();
}

class _LaporanKendalaPageState extends State<LaporanKendalaPage> {
  final _judulController = TextEditingController();
  final _isiController = TextEditingController();
  
  List<dynamic> _categories = [];
  String? _selectedCategoryId; 
  File? _selectedFile; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // 1. AMBIL KATEGORI KENDALA
  Future<void> _fetchCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(ApiConstants.kategoriKendala),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _categories = data['data'] ?? [];
          if (_categories.isNotEmpty) {
            _selectedCategoryId = _categories[0]['id'].toString();
          }
        });
      } else {
        debugPrint("Gagal memuat kategori. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Gagal mengambil kategori: $e");
    }
  }

  // 2. AMBIL GAMBAR DARI GALERI
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

  // 3. SIMPAN LAPORAN KENDALA KE LARAVEL
  Future<void> _simpanLaporan() async {
    if (_judulController.text.isEmpty || _isiController.text.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi semua kolom laporan!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      var uri = Uri.parse(ApiConstants.laporanKendala);
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });

      request.fields['id_category_report'] = _selectedCategoryId!;
      request.fields['title'] = _judulController.text;
      request.fields['content'] = _isiController.text;

      if (_selectedFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'attachment', 
          _selectedFile!.path,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      setState(() => _isLoading = false);

      if (response.statusCode == 201) {
        final resData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resData['message'] ?? "Sukses menyimpan laporan!")),
        );
        Navigator.pop(context); 
      } else {
        debugPrint("Respon error server: ${response.body}");
        final resData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: ${resData['message'] ?? response.body}")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan jaringan: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);
    const darkTealColor = Color(0xFF264653);
    const bgLightColor = Color(0xFFF4F7F9);

    return Scaffold(
      backgroundColor: bgLightColor,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Laporan & Kendala',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
      ? const Center(child: CircularProgressIndicator(color: primaryColor))
      : SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Laporkan Hal Lain atau Kendala Lapangan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkTealColor),
              ),
              const SizedBox(height: 20),

              // --- INPUT KATEGORI LAPORAN ---
              _buildLabel("Kategori Kendala"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategoryId,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
                    items: _categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['id'].toString(),
                        child: Text(cat['name'].toString(), style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategoryId = val;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- INPUT JUDUL LAPORAN ---
              _buildLabel("Judul Laporan"),
              _buildTextField(
                controller: _judulController,
                hint: "Masukkan judul laporan kendala...",
              ),
              const SizedBox(height: 20),

              // --- INPUT ISI LAPORAN ---
              _buildLabel("Isi Laporan / Keterangan"),
              _buildTextField(
                controller: _isiController,
                hint: "Ceritakan detail kendala atau hal lainnya di sini...",
                maxLines: 6,
              ),
              const SizedBox(height: 25),

              // --- SECTION UPLOAD LAMPIRAN ---
              _buildLabel("Foto Bukti / Lampiran"),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: bgLightColor,
                        borderRadius: BorderRadius.circular(12),
                        image: _selectedFile != null 
                            ? DecorationImage(image: FileImage(_selectedFile!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _selectedFile == null 
                          ? const Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 36)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage, 
                            style: ElevatedButton.styleFrom(
                              backgroundColor: bgLightColor,
                              elevation: 0,
                              foregroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            icon: Icon(_selectedFile == null ? Icons.upload_file : Icons.edit, size: 16),
                            label: Text(
                              _selectedFile == null ? "Pilih Gambar" : "Ubah Gambar",
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Mendukung format gambar PNG, JPG, JPEG.",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40), 
            ],
          ),
        ),
      
      // --- PERBAIKAN UTAMA: TOMBOL PINDAH KE BAWAH SCR KUNCI & AMAN DARI NAVIGASI HP ---
      bottomNavigationBar: _isLoading 
          ? const SizedBox.shrink() 
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 16.0, top: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: const Text("Batal", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _simpanLaporan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            elevation: 4,
                            shadowColor: primaryColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text("Kirim Laporan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
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

  Widget _buildTextField({required TextEditingController controller, required String hint, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}