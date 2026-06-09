import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile/core/constants/api_constants.dart';
import 'form_waste_out.dart'; 

class PilihMetodeKeluarPage extends StatefulWidget {
  const PilihMetodeKeluarPage({super.key});

  @override
  State<PilihMetodeKeluarPage> createState() => _PilihMetodeKeluarPageState();
}

class _PilihMetodeKeluarPageState extends State<PilihMetodeKeluarPage> {
  List<dynamic> _methodsList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMethods();
  }

  Future<void> _fetchMethods() {
    return Future(() async {
      try {
        final response = await http.get(Uri.parse(ApiConstants.wasteOutMethods));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _methodsList = data['data'] ?? data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Gagal memuat metode (Status: ${response.statusCode})';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Masalah koneksi internet: $e';
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tema warna khusus Sampah Keluar (Oranye/Merah Bata)
    const primaryOutColor = Color(0xFFE76F51); 
    const gradientStart = Color(0xFFF4A261);
    const gradientEnd = Color(0xFFE76F51);
    const bgLightColor = Color(0xFFF4F7F9);

    return Scaffold(
      backgroundColor: bgLightColor,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: primaryOutColor,
        elevation: 0,
        leading: IconButton(
          padding: const EdgeInsets.only(top: 15),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 15),
          child: Text(
            'Pilih Metode Keluar',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMethods,
        color: primaryOutColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- BANNER HEADER SAMPAH KELUAR ---
              Container(
                margin: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [gradientStart, gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientEnd.withOpacity(0.3),
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
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sampah Keluar',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Pencatatan data sampah yang keluar dari sistem tracking/gudang pusat.',
                              style: TextStyle(color: Colors.white, fontSize: 11, height: 1.3),
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
                  'Pilih tujuan pemrosesan/distribusi sampah:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF264653)),
                ),
              ),
              const SizedBox(height: 15),

              // --- LOGIKA UTAMA (LOADING, ERROR, DATA) ---
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator(color: primaryOutColor)),
                )
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 10),
                        ElevatedButton(onPressed: _fetchMethods, child: const Text('Coba Lagi')),
                      ],
                    ),
                  ),
                )
              else
                // --- GRID METODE KELUAR DINAMIS (Otomatis Berdampingan) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _methodsList.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.95,
                    ),
                    itemBuilder: (context, index) {
                      final item = _methodsList[index];
                      return _buildMethodTile(
                        title: item['name'] ?? '-',
                        description: item['description'] ?? '',
                        photoPath: item['photo'],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FormInputKeluarPage(selectedMethod: item),
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

  // --- HELPER METODE TILE DENGAN ICON FALLBACK SESUAI DATABASE ---
  Widget _buildMethodTile({
    required String title,
    required String description,
    required String? photoPath,
    required VoidCallback onTap,
  }) {
    // Logika penentuan ikon pintar sesuai isi text name di database (gambar_21.png)
    IconData methodIcon = Icons.output_rounded; 
    if (title.toLowerCase().contains('jual')) {
      methodIcon = Icons.monetization_on_outlined; // Ikon koin uang untuk Penjualan
    } else if (title.toLowerCase().contains('landfill')) {
      methodIcon = Icons.delete_sweep_outlined;    // Ikon TPA untuk Landfill
    } else if (title.toLowerCase().contains('insinerasi')) {
      methodIcon = Icons.local_fire_department_outlined; // Ikon Api untuk dibakar
    } else if (title.toLowerCase().contains('kompos')) {
      methodIcon = Icons.compost_outlined;        // Ikon daun/pupuk untuk Komposting
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDECE8), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF4A261).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
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
              // Wadah Lingkaran Ikon Bawaan karena kolom photo NULL (sesuai gambar_21.png)
              Container(
                width: 65,
                height: 65,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: ClipOAuth( // Mengamankan jika ke depan admin iseng upload foto web
                  child: photoPath != null && photoPath.isNotEmpty
                      ? Image.network(
                          "${ApiConstants.storageUrl}/$photoPath",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(methodIcon, color: const Color(0xFFE76F51), size: 32),
                        )
                      : Icon(methodIcon, color: const Color(0xFFE76F51), size: 32),
                ),
              ),
              const SizedBox(height: 12),
              // Nama Metode
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF264653)),
              ),
              const SizedBox(height: 4),
              // Keterangan Kecil di bawah nama metode
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Clip Sederhana
class ClipOAuth extends StatelessWidget {
  final Widget child;
  const ClipOAuth({super.key, required this.child});
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(50), child: child);
}