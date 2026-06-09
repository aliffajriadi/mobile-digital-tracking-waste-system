import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'select_input_page.dart';
import '../../history/pages/detail_waste_page.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

class LaporanDataHarianPage extends StatefulWidget {
  const LaporanDataHarianPage({super.key});

  @override
  State<LaporanDataHarianPage> createState() => _LaporanDataHarianPageState();
}

class _LaporanDataHarianPageState extends State<LaporanDataHarianPage> {
  final _searchController = TextEditingController();
  List<dynamic> _laporanList = [];
  bool _isLoading = true;

  // --- Tambahan State Baru untuk Filter & Pencarian ---
  String _selectedKategori = 'Semua'; 
  String _searchQuery = '';
  final List<String> _categories = ['Semua', 'Organik', 'Non Organik', 'B3'];

  @override
  void initState() {
    super.initState();
    _fetchLaporan();
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLaporan() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(ApiConstants.laporanHarian),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));
      
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          setState(() {
            _laporanList = data['data'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          debugPrint("Gagal dari API: ${data['message']}");
          _loadMockDataFallback(); // Fallback data lokal jika API kamu belum diubah backend-nya
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
        debugPrint("Server Error Status Code: ${response.statusCode}");
        _loadMockDataFallback(); 
      }
    } catch (e) {
      debugPrint("Error Catch Laporan Harian: $e");
      if (mounted) setState(() => _isLoading = false);
      _loadMockDataFallback();
    }
  }

  // Helper jika API backend-mu belum siap mengirimkan struktur data 'Stok' baru
  void _loadMockDataFallback() {
    setState(() {
      _laporanList = [
        {"id": 1, "kategori": "Daun Kering", "jenis_kategori": "Organik", "jumlah": "120 Kg", "isBotol": false},
        {"id": 2, "kategori": "Sisa Makanan", "jenis_kategori": "Organik", "jumlah": "45 Kg", "isBotol": false},
        {"id": 3, "kategori": "Botol Plastik", "jenis_kategori": "Non Organik", "jumlah": "300 Pcs", "isBotol": true},
        {"id": 4, "kategori": "Kardus Bekas", "jenis_kategori": "Non Organik", "jumlah": "85 Kg", "isBotol": false},
        {"id": 5, "kategori": "Baterai Bekas", "jenis_kategori": "B3", "jumlah": "12 Kg", "isBotol": false},
        {"id": 6, "kategori": "Lampu Neon", "jenis_kategori": "B3", "jumlah": "8 Pcs", "isBotol": false},
      ];
      _isLoading = false;
    });
  }

  // --- Fungsi Filter & Search Logic ---
  List<dynamic> _getFilteredList() {
    return _laporanList.where((item) {
      final namaSampah = (item['kategori'] ?? '').toString().toLowerCase();
      final katSampah = (item['jenis_kategori'] ?? item['cat_name'] ?? '').toString();

      final cocokKategori = _selectedKategori == 'Semua' || katSampah.toLowerCase() == _selectedKategori.toLowerCase();
      final cocokSearch = namaSampah.contains(_searchQuery);

      return cocokKategori && cocokSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);
    const darkTealColor = Color(0xFF264653);
    const bgLightColor = Color(0xFFF4F7F9);

    final filteredData = _getFilteredList();

    return Scaffold(
      backgroundColor: bgLightColor,
      body: Column(
        children: [
          // HEADER + TEXTFIELD SEARCH
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
            decoration: const BoxDecoration(color: primaryColor),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Pusat Informasi Stok TPST', 
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  height: 42,
                  decoration: BoxDecoration(color: const Color(0xFFEAEFF2), borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari jenis sampah...', 
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.black45), 
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- HORIZONTAL CHIPS FILTER KATEGORI ---
          Container(
            height: 55,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final kat = _categories[index];
                final isSelected = _selectedKategori == kat;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(kat),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    backgroundColor: bgLightColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : darkTealColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedKategori = kat;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // AREA LIST DATA (BISA GROUPING MAUPUN SINGLE FILTER)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : filteredData.isEmpty
                    ? const Center(child: Text("Jenis atau kategori sampah tidak ditemukan"))
                    : _selectedKategori == 'Semua' && _searchQuery.isEmpty
                        ? _buildGroupedListView(filteredData, primaryColor)
                        : _buildNormalListView(filteredData, primaryColor),
          ),


          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectInputPage())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkTealColor, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Tambah Transaksi Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // LAYOUT 1: Jika filter "Semua Kategori", data dikelompokkan per judul kategori
  Widget _buildGroupedListView(List<dynamic> data, Color primaryColor) {
    // Memilah data lokal secara manual berdasarkan kategorinya
    final organikList = data.where((e) => (e['jenis_kategori'] ?? '').toString().toLowerCase() == 'organik').toList();
    final nonOrganikList = data.where((e) => (e['jenis_kategori'] ?? '').toString().toLowerCase() == 'non organik').toList();
    final b3List = data.where((e) => (e['jenis_kategori'] ?? '').toString().toLowerCase() == 'b3').toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (organikList.isNotEmpty) ...[
          _buildCategoryHeader("Sampah Organik", Colors.green),
          ...organikList.map((item) => _buildItemInkWell(item, primaryColor)),
          const SizedBox(height: 10),
        ],
        if (nonOrganikList.isNotEmpty) ...[
          _buildCategoryHeader("Sampah Non Organik", Colors.blue),
          ...nonOrganikList.map((item) => _buildItemInkWell(item, primaryColor)),
          const SizedBox(height: 10),
        ],
        if (b3List.isNotEmpty) ...[
          _buildCategoryHeader("Bahan Berbahaya & Beracun (B3)", Colors.redAccent),
          ...b3List.map((item) => _buildItemInkWell(item, primaryColor)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  // LAYOUT 2: Jika disaring spesifik atau sedang mengetik kolom pencarian
  Widget _buildNormalListView(List<dynamic> data, Color primaryColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return _buildItemInkWell(item, primaryColor);
      },
    );
  }

  // Widget Header pemisah kategori kelompok data
  Widget _buildCategoryHeader(String title, Color indicatorColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 6),
      child: Row(
        children: [
          Container(width: 4, height: 16, color: indicatorColor),
          const SizedBox(width: 8),
          Text(
            title, 
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF264653))
          ),
        ],
      ),
    );
  }

  // Struktur navigasi klik item log kartu
  Widget _buildItemInkWell(Map<String, dynamic> item, Color arrowColor) {
    return InkWell(
      onTap: () {
        // Halaman detail sampah nanti tinggal dipasang di file detail_waste_page.dart
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => DetailLaporanPage(idLaporan: item['id'] ?? 0), 
          ),
        );
      },
      child: _buildLaporanCard(item, arrowColor),
    );
  }

  Widget _buildLaporanCard(Map<String, dynamic> item, Color arrowColor) {
    bool isBotol = item['isBotol'] == true || item['isBotol'] == 1;
    String kategoriLabel = item['jenis_kategori'] ?? 'Umum';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.black12.withOpacity(0.05))
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: const BoxDecoration(color: Color(0xFFE5E9EC), shape: BoxShape.circle),
            child: Center(
              child: isBotol
                  ? const Icon(Icons.opacity_rounded, color: Colors.blue, size: 24)
                  : const Icon(Icons.layers_outlined, color: Colors.teal, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['kategori'] ?? 'N/A', 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF264653))
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF0F4F8), borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    kategoriLabel, 
                    style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w500)
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Stok Tersedia", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text(
                item['jumlah'] ?? '0', 
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF264653))
              ),
            ],
          ),
          const SizedBox(width: 10),
          Icon(Icons.arrow_forward_ios_rounded, color: arrowColor, size: 14),
        ],
      ),
    );
  }
}