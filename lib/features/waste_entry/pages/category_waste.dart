import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'subcategory_waste.dart';
import 'package:mobile/core/constants/api_constants.dart';

class PilihKategoriPage extends StatefulWidget {
  const PilihKategoriPage({Key? key}) : super(key: key);

  @override
  State<PilihKategoriPage> createState() => _PilihKategoriPageState();
}

class _PilihKategoriPageState extends State<PilihKategoriPage> {
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(ApiConstants.categories),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _categories = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Gagal memuat kategori';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error server: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Koneksi gagal. Pastikan backend menyala.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Background abu-abu ekstra soft (Modern UI)
      appBar: AppBar(
        title: const Text(
          'Pilih Kategori Sampah',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700, 
            color: Colors.white,
            letterSpacing: 0,
          ),
        ),
        backgroundColor: const Color(0xFF14A38B), // Hijau Tosca khas aplikasi
        centerTitle: false,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), // Ikon iOS style lebih rapi
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: const Color(0xFF14A38B)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage, 
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500)
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _fetchCategories,
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14A38B),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub-header modern dengan garis dekoratif tipis
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      color: Colors.white,
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Kategori Sampah',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B), // Navy gelap maskulin
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Sesuaikan dengan jenis limbah fisik yang Anda terima',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B), // Abu-abu slate kalem
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    
                    // List kategori utama
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          
                          // Palet warna aksen lingkaran ikon (Soft / Pastel premium vibe)
                          List<Color> accentColors = [
                            const Color(0xFFE2F9F3), // Soft Tosca
                            const Color(0xFFFFF4E5), // Soft Orange
                            const Color(0xFFFFEAEB), // Soft Red (B3)
                          ];
                          List<Color> iconColors = [
                            const Color(0xFF14A38B),
                            const Color(0xFFF59E0B),
                            const Color(0xFFEF4444),
                          ];
                          
                          Color bgIconColor = accentColors[index % accentColors.length];
                          Color iconColor = iconColors[index % iconColors.length];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white, // Kartu dasar putih bersih
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withOpacity(0.04), // Bayangan halus anti-kaku
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: const Color(0xFFF1F5F9)), // Border luar tipis super bersih
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SubCategoryPage(category: category),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      // Lingkaran Foto/Ikon bergaya elegan
                                      category['photo_url'] != null && category['photo_url'].toString().isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.network(
                                                category['photo_url'],
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    width: 56,
                                                    height: 56,
                                                    color: bgIconColor,
                                                    child: Icon(Icons.image_not_supported_rounded, color: iconColor, size: 24),
                                                  );
                                                },
                                              ),
                                            )
                                          : Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: bgIconColor,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.delete_sweep_rounded, 
                                                color: iconColor, 
                                                size: 26,
                                              ),
                                            ),
                                      const SizedBox(width: 16),
                                      
                                      // Teks Informasi dengan Kontras Hirarki Font yang Kuat
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              category['name'] ?? 'Tanpa Nama',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700, // Dipertebal agar kontras
                                                color: Color(0xFF1E293B),  // Navy gelap modern
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              category['description'] ?? 'Tidak ada deskripsi',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis, // Potong teks jika kepanjangan biar rapi
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xFF64748B), // Deskripsi soft slate grey
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      
                                      // Ikon panah pelengkap kecil & manis
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Color(0xFFCBD5E1),
                                        size: 16,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}