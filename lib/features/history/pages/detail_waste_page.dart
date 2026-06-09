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
            'Detail Laporan',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
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
                      // --- TOMBOL EDIT & HAPUS ---
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 45,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // TODO: Aksi Edit Data
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: yellowEdit,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                label: const Text("Edit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 45,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // TODO: Aksi Hapus Data
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orangeWarning,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                                label: const Text("Hapus", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // --- KARTU WAKTU & TANGGAL ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, color: darkBlueColor, size: 28),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _detailData!['waktu_tanggal'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: darkBlueColor, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _detailData!['waktu_jam'],
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- GRID: JENIS SAMPAH & TOTAL INPUT ---
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 120,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Jenis Sampah", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _detailData!['sub_kategori'],
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                                        ),
                                      ),
                                      Icon(
                                        _detailData!['sub_kategori'].toString().toLowerCase().contains('botol')
                                            ? Icons.local_drink_rounded
                                            : Icons.oil_barrel_rounded,
                                        color: Colors.blue,
                                        size: 35,
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 120,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Total Input", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        "${_detailData!['jumlah']} ",
                                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w200, color: Colors.white),
                                      ),
                                      Text(
                                        _detailData!['satuan'],
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- KARTU SUMBER SAMPAH ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 14, color: darkBlueColor),
                            children: [
                              const TextSpan(text: "Sumber sampah : ", style: TextStyle(fontWeight: FontWeight.w500)),
                              TextSpan(text: _detailData!['sumber'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- KARTU CATATAN DARI PIC ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Catatan Dari PIC",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkBlueColor),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _detailData!['catata_atau_notes'] ?? _detailData!['catatan'],
                              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- SECTION LAMPIRAN ---
                      const Text(
                        "Lampiran",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBlueColor),
                      ),
                      const SizedBox(height: 12),
                      
                      _detailData!['foto'] == null
                          ? const Text("Tidak ada lampiran foto", style: TextStyle(color: Colors.grey, fontSize: 13))
                          : Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _detailData!['foto'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey));
                                  },
                                ),
                              ),
                            ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}