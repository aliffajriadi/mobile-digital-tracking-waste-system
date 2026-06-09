import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../widgets/history_card.dart';
import '../widgets/filter_bottom_sheet.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final _historyService = HistoryService();
  
  Map<String, dynamic> _groupedRiwayat = {};
  List<dynamic> _categories = [];
  bool _isLoading = true;

  String _searchQuery = "";
  int? _selectedCategoryId;
  String _selectedCategoryName = "Semua";

  @override
  void initState() {
    super.initState();
    _getRiwayatData();
  }

  Future<void> _getRiwayatData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final resData = await _historyService.fetchRiwayatLaporan(
        searchQuery: _searchQuery,
        selectedCategoryId: _selectedCategoryId,
      );

      if (mounted) {
        setState(() {
          _groupedRiwayat = Map<String, dynamic>.from(resData['data'] ?? {});
          _categories = resData['categories'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error get riwayat view: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FilterBottomSheet(
          categories: _categories,
          selectedCategoryId: _selectedCategoryId,
          onCategorySelected: (id, name) {
            setState(() {
              _selectedCategoryId = id;
              _selectedCategoryName = name;
            });
            Navigator.pop(context);
            _getRiwayatData();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);
    const bgLightColor = Color(0xFFF4F7F9);
    const darkBlueColor = Color(0xFF264653);

    final tanggalList = _groupedRiwayat.keys.toList();

    return Scaffold(
      backgroundColor: bgLightColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        // Menurunkan posisi ikon bawaan tombol kembali
        leading: Padding(
          padding: const EdgeInsets.only(top: 10.0, left: 6.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // Menurunkan posisi teks judul AppBar
        title: const Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            'Riwayat Laporan',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Bar Pencarian & Tombol Filter Pendukung
          Container(
            color: primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 45,
                    child: TextField(
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        _getRiwayatData();
                      },
                      decoration: const InputDecoration(
                        hintText: "Cari riwayat aktivitas...",
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _openFilterSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      color: darkBlueColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                  ),
                )
              ],
            ),
          ),

          // Area Tampilan Data Log Berkelompok Tanggal
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : tanggalList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off_rounded, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              "Tidak ada data riwayat ditemukan",
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tanggalList.length,
                        itemBuilder: (context, index) {
                          final String tanggal = tanggalList[index];
                          final List items = (_groupedRiwayat[tanggal] ?? []) as List;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sub-Header label Kelompok Tanggal
                              Padding(
                                padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8),
                                child: Text(
                                  tanggal,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              
                              // List Kartu Riwayat di tanggal yang bersangkutan
                              ...items.map((item) => HistoryCard(item: item)).toList(),
                              const SizedBox(height: 4),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}