import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile/core/constants/api_constants.dart';

class DetailKendalaPage extends StatefulWidget {
  final String reportId;

  const DetailKendalaPage({super.key, required this.reportId});

  @override
  State<DetailKendalaPage> createState() => _DetailKendalaPageState();
}

class _DetailKendalaPageState extends State<DetailKendalaPage> {
  Map<String, dynamic>? _detailData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetailKendala();
  }

  Future<void> _fetchDetailKendala() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.laporanKendala}/${widget.reportId}"),
      );

      if (response.statusCode == 200) {
        final resBody = json.decode(response.body);
        setState(() {
          _detailData = resBody['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Gagal memuat data dari server";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan jaringan: $e";
        _isLoading = false;
      });
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
        toolbarHeight: 80,
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          padding: const EdgeInsets.only(top: 15),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Tutup halaman detail dan kembali ke halaman riwayat
            Navigator.pop(context); 
          },
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
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategori Kendala Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          _detailData?['category_name'] ?? 'Kategori Umum',
                          style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Judul Kendala
                      Text(
                        _detailData?['title'] ?? '-',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkTealColor),
                      ),
                      const Divider(height: 30, thickness: 1),

                      const Text(
                        "Keterangan / Laporan Lapangan:",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Text(
                          _detailData?['content'] ?? '-',
                          style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Bukti Foto / Lampiran
                      const Text(
                        "Foto Bukti / Lampiran:",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      _detailData?['attachment_path'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _detailData!['attachment_path'],
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildEmptyImagePlaceholder();
                                },
                              ),
                            )
                          : _buildEmptyImagePlaceholder(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E9EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40),
          SizedBox(height: 8),
          Text("Tidak ada lampiran foto bukti", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}