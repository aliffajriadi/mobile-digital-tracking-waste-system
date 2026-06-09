import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile/core/constants/api_constants.dart'; 
import 'form_input_processed.dart'; 

class LaporanOlahanPage extends StatefulWidget {
  const LaporanOlahanPage({super.key});

  @override
  State<LaporanOlahanPage> createState() => _LaporanOlahanPageState();
}

class _LaporanOlahanPageState extends State<LaporanOlahanPage> {
  List<dynamic> _processedWasteList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProcessedWaste();
  }

  // --- FUNGSI MENGAMBIL DATA DARI API LARAVEL ---
  Future<void> _fetchProcessedWaste() {
    return Future(() async {
      try {
        final response = await http.get(Uri.parse(ApiConstants.processedWaste));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            // Menyesuaikan jika Laravel membungkus data dalam field 'data' atau langsung array
            _processedWasteList = data['data'] ?? data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Gagal memuat data (Status: ${response.statusCode})';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan koneksi: $e';
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);
    const processedGradientStart = Color(0xFF3A9D8F); 
    const processedGradientEnd = Color(0xFF2A7B6F);
    const bgLightColor = Color(0xFFF4F7F9);

    return Scaffold(
      backgroundColor: bgLightColor,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          padding: const EdgeInsets.only(top: 15),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 15),
          child: Text(
            'Pilih Jenis Olahan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProcessedWaste,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- BANNER HEADER ---
              Container(
                margin: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [processedGradientStart, processedGradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: processedGradientEnd.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.recycling_rounded,
                          color: Colors.white,
                          size: 45,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Olahan Sampah',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Sampah yang diolah kembali dan bisa dimanfaatkan (kompos, pelet plastik, dll)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- JUDUL SEKSI ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Text(
                  'Lapor & catat data sampah sesuai jenis olahan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF264653),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // --- LOGIKA KONDISI: LOADING, ERROR, ATAU TAMPIL DATA ---
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Center(child: CircularProgressIndicator(color: primaryColor)),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Center(
                    child: Column(
                      children: [
                        Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _fetchProcessedWaste,
                          child: const Text('Coba Lagi'),
                        )
                      ],
                    ),
                  ),
                )
              else if (_processedWasteList.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Center(child: Text('Belum ada data jenis olahan.')),
                )
              else
                // --- GRID DATA DINAMIS (Menggantikan hardcode Kompos) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _processedWasteList.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,         // Menampilkan 2 kolom berdampingan
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.95,    // Proporsi tinggi kotak tile
                    ),
                    itemBuilder: (context, index) {
                      final item = _processedWasteList[index];
                      return _buildCategoryTile(
                        title: item['name'] ?? '-',
                        photoPath: item['photo'], // Path gambar dari database
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FormInputOlahanPage(selectedOlahan: item),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER TILE GRID (DIPERBARUI DENGAN FITUR FOTO) ---
  Widget _buildCategoryTile({
    required String title,
    required String? photoPath,
    required VoidCallback onTap,
  }) {
    // Menentukan ikon fallback bawaan jika tidak ada gambar di database
    IconData defaultIcon = Icons.inventory_2_outlined;
    if (title.toLowerCase().contains('kompos')) {
      defaultIcon = Icons.park_rounded;
    } else if (title.toLowerCase().contains('plastik')) {
      defaultIcon = Icons.layers_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 14, 193, 187),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Wadah Gambar / Ikon
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F5F3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: photoPath != null && photoPath.isNotEmpty
                      ? Image.network(
                          "${ApiConstants.storageUrl}/$photoPath",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(defaultIcon, color: const Color(0xFF14A38B), size: 38);
                          },
                        )
                      : Icon(defaultIcon, color: const Color(0xFF14A38B), size: 38),
                ),
              ),
              const SizedBox(height: 12),
              // Judul Jenis Olahan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF264653),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}