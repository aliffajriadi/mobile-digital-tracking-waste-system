import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailLaporanPage extends StatefulWidget {
  final int idLaporan; // Terima ID dari halaman list data

  const DetailLaporanPage({super.key, required this.idLaporan});

  @override
  State<DetailLaporanPage> createState() => _DetailLaporanPageState();
}

class _DetailLaporanPageState extends State<DetailLaporanPage> {
  Map<String, dynamic>? _detailData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetailLaporan();
  }

  Future<void> _fetchDetailLaporan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      // Ambil data berdasarkan idLaporan yang dikirim dari halaman sebelumnya
      final url = "${ApiConstants.laporanHarian}/${widget.idLaporan}";

      // 4. KIRIM DENGAN HEADER AUTHENTICATION
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token', // <--- Kuncinya ada di sini!
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (mounted) {
          setState(() {
            _detailData = resData['data'];
            _isLoading = false;
          });
        }
      } else {
        // Print status code untuk mempermudah pelacakan (misal 401 Unauthorized)
        debugPrint("Gagal memuat. Status Code: ${response.statusCode}");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error Detail: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);
    const bgLightColor = Color(0xFFF4F7F9);
    const darkBlueColor = Color(0xFF264653);
    const orangeWarning = Color(0xFFE76F51);
    const yellowEdit = Color(0xFFE9C46A);

    return Scaffold(
      backgroundColor: bgLightColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Detail Laporan',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _detailData == null
              ? const Center(child: Text("Gagal memuat detail data laporan"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER HIGHLIGHT (JENIS SAMPAH & TOTAL INPUT) ---
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: const BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Total Input", style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            "${_detailData!['jumlah']} ",
                                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                                          ),
                                          Text(
                                            _detailData!['satuan'],
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.scale_rounded, color: Colors.white, size: 28),
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _detailData!['sub_kategori'].toString().toLowerCase().contains('botol')
                                          ? Icons.local_drink_rounded
                                          : Icons.delete_outline_rounded,
                                      color: Colors.orange,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Jenis Sampah", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        Text(
                                          _detailData!['sub_kategori'],
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBlueColor),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- INFORMASI LAINNYA ---
                      const Text(
                        "Informasi Detail",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBlueColor),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Waktu
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.access_time_rounded, color: Colors.blue, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Waktu Tercatat", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Text(_detailData!['waktu_tanggal'], style: const TextStyle(fontWeight: FontWeight.bold, color: darkBlueColor, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text(_detailData!['waktu_jam'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                            // Sumber
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.place_rounded, color: Colors.purple, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Sumber Sampah", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Text(_detailData!['sumber'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: darkBlueColor, fontSize: 14)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                            // Catatan
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFFE2F9F3), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.notes_rounded, color: primaryColor, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Catatan PIC", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _detailData!['catata_atau_notes'] ?? _detailData!['catatan'],
                                        style: const TextStyle(color: darkBlueColor, fontSize: 14, height: 1.4),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- SECTION LAMPIRAN ---
                      const Text(
                        "Lampiran Foto",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBlueColor),
                      ),
                      const SizedBox(height: 12),
                      
                      _detailData!['foto'] == null
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.image_not_supported_rounded, color: Colors.grey.shade300, size: 48),
                                  const SizedBox(height: 8),
                                  const Text("Tidak ada lampiran foto", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(maxHeight: 250),
                                child: Image.network(
                                  _detailData!['foto'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade100,
                                      child: const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                                    );
                                  },
                                ),
                              ),
                            ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
      bottomNavigationBar: _isLoading || _detailData == null
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                ]
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Aksi Edit Data
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: yellowEdit,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                        label: const Text("Edit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Aksi Hapus Data
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeWarning,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                        label: const Text("Hapus", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}