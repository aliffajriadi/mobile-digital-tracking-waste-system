import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'form_waste_entry.dart';
import 'package:mobile/core/constants/api_constants.dart';

class SubCategoryPage extends StatefulWidget {
  final Map<String, dynamic> category; 

  const SubCategoryPage({Key? key, required this.category}) : super(key: key);

  @override
  State<SubCategoryPage> createState() => _SubCategoryPageState();
}

class _SubCategoryPageState extends State<SubCategoryPage> {
  List<dynamic> _subCategories = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchSubCategories();
  }

  Future<void> _fetchSubCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      final categoryId = widget.category['id'];

      final response = await http.get(
        Uri.parse('${ApiConstants.subCategories}/$categoryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _subCategories = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Gagal memuat jenis sampah';
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
    print("KATEGORI YANG SEDANG DIBUKA SAAT INI: ${widget.category}");
    const primaryColor = Color(0xFF14A38B);
    const bgLightColor = Color(0xFFF8FAFC); 

    String categoryName = widget.category['name'] ?? 'Jenis Laporan';
    String categoryDesc = widget.category['description'] ?? '-';

    // --- LOGIKA WARNA BERDASARKAN ID DATABASE ---
    Color bgIconColor;
    Color iconColor;
    final int categoryId = widget.category['id'] ?? 0;

    if (categoryId == 2) { 
      // ID 2 = Anorganik (Kuning/Oranye Pastel)
      bgIconColor = const Color(0xFFFFF7E6); 
      iconColor = const Color.fromARGB(255, 234, 191, 0);
    } else if (categoryId == 3) { 
      // ID 3 = B3 (Merah Pastel)
      bgIconColor = const Color(0xFFFFEAEB); 
      iconColor = const Color(0xFFEF4444);
    } else { 
      // ID 1 / Lainnya = Organik (Hijau Pastel)
      bgIconColor = const Color(0xFFE2F9F3); 
      iconColor = const Color(0xFF14A38B);
    }

    return Scaffold(
      backgroundColor: bgLightColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: false, 
        titleSpacing: 0,    
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pilih Jenis Sampah',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.layers_clear_rounded, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage, 
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500)
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _fetchSubCategories,
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- BANNER HEADER ---
                      // --- BANNER HEADER ATAS (Sekarang otomatis berubah warna!) ---
                      Container(
                        margin: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              iconColor.withOpacity(0.85), // Warna gradasi kiri mengikuti kategori
                              iconColor,                   // Warna gradasi kanan mengikuti kategori
                            ], 
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ]
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.eco_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      categoryName,
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      categoryDesc,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, height: 1.3, fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 22),
                        child: Text(
                          'Pilih Sub-Kategori Spesifik:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- GRID VIEW DENGAN WARNA BACKGROUND KOTAK FOTO DINAMIS ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _subCategories.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, 
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 185, 
                          ),
                          itemBuilder: (context, index) {
                            final subCat = _subCategories[index];

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white, 
                                borderRadius: BorderRadius.circular(16),
                                // --- TRIK BARU: Border luar kotak ikut warna kategori induk ---
                                border: Border.all(
                                  color: iconColor.withOpacity(0.4), // Pakai iconColor (Kuning/Merah/Hijau)
                                  width: 2.5, // Kita tebalkan bordernya agar kelihatan jelas
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: iconColor.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => InputSampahPage(selectedSubCategory: subCat),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Bingkai foto dengan warna background pastel
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: bgIconColor, 
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: subCat['photo_url'] != null && subCat['photo_url'].toString().isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(14),
                                                  child: Image.network(
                                                    subCat['photo_url'],
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => 
                                                        Icon(Icons.restore_from_trash_rounded, color: iconColor, size: 32),
                                                  ),
                                                )
                                              : Icon(Icons.restore_from_trash_rounded, color: iconColor, size: 32),
                                        ),
                                        
                                        const SizedBox(height: 12),
                                        
                                        // Nama Sub-Kategori (Warnanya ikut dinamis)
                                        Text(
                                          subCat['name'] ?? 'Tanpa Nama',
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13, 
                                            fontWeight: FontWeight.w800, 
                                            color: iconColor, // <--- WARNA TEKS IKUT KATEGORI (Kuning/Merah/Hijau)
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }
}