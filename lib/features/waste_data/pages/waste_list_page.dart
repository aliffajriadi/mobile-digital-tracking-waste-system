import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'select_input_page.dart';
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
  final List<String> _categories = ['Semua', 'Organik', 'Non Organik', 'B3', 'Hasil Olahan'];

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
        Uri.parse(ApiConstants.wasteStocks),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final rawList = data['data'] ?? [];
          setState(() {
            _laporanList = rawList is List ? rawList : [];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          debugPrint("Gagal dari API: ${data['message']}");
          _loadMockDataFallback();
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

  // Helper jika API backend belum siap mengirimkan data atau fallback
  void _loadMockDataFallback() {
    setState(() {
      _laporanList = [
        {"id": 1, "kategori": "Daun Kering", "jenis_kategori": "Organik", "jumlah": "120 Kg", "isBotol": false},
        {"id": 2, "kategori": "Sisa Makanan", "jenis_kategori": "Organik", "jumlah": "45 Kg", "isBotol": false},
        {"id": 3, "kategori": "Botol Plastik", "jenis_kategori": "Non Organik", "jumlah": "300 Pcs", "isBotol": true},
        {"id": 4, "kategori": "Kardus Bekas", "jenis_kategori": "Non Organik", "jumlah": "85 Kg", "isBotol": false},
        {"id": 5, "kategori": "Plastik Kemasan", "jenis_kategori": "Non Organik", "jumlah": "62 Kg", "isBotol": false},
        {"id": 6, "kategori": "Kaleng Bekas", "jenis_kategori": "Non Organik", "jumlah": "25 Kg", "isBotol": false},
        {"id": 7, "kategori": "Baterai Bekas", "jenis_kategori": "B3", "jumlah": "12 Kg", "isBotol": false},
        {"id": 8, "kategori": "Lampu Neon", "jenis_kategori": "B3", "jumlah": "8 Pcs", "isBotol": false},
        {"id": 9, "kategori": "Kompos Organik", "jenis_kategori": "Hasil Olahan", "jumlah": "150 Kg", "isBotol": false},
      ];
      _isLoading = false;
    });
  }

  // --- Helper Kategori Checker ---
  bool _isNonOrganik(dynamic item) {
    final kat = _getItemCategory(item).toLowerCase();
    final name = _getItemName(item).toLowerCase();
    return kat.contains('non') || kat.contains('anorganik') || name.contains('botol') || name.contains('kardus') || name.contains('plastik') || name.contains('kaleng') || name.contains('kaca');
  }

  bool _isOrganik(dynamic item) {
    final kat = _getItemCategory(item).toLowerCase();
    return kat.contains('organik') && !kat.contains('non') && !kat.contains('anorganik');
  }

  bool _isB3(dynamic item) {
    final kat = _getItemCategory(item).toLowerCase();
    return kat.contains('b3');
  }

  bool _isHasilOlahan(dynamic item) {
    final kat = _getItemCategory(item).toLowerCase();
    return kat.contains('olahan') || kat.contains('hasil');
  }

  String _getItemName(dynamic item) {
    if (item is Map) {
      return (item['kategori'] ?? item['name'] ?? item['sub_category_name'] ?? item['jenis_sampah'] ?? item['title'] ?? 'Tanpa Nama').toString();
    }
    return 'Tanpa Nama';
  }

  String _getItemCategory(dynamic item) {
    if (item is Map) {
      if (item['category'] is Map) {
        return (item['category']['name'] ?? '').toString();
      }
      return (item['jenis_kategori'] ?? item['category_name'] ?? item['cat_name'] ?? item['category'] ?? item['kategori_sampah'] ?? 'Umum').toString();
    }
    return 'Umum';
  }

  dynamic _getItemQuantity(dynamic item) {
    if (item is Map) {
      return item['jumlah'] ?? item['current_stock'] ?? item['total_weight'] ?? item['stock'] ?? item['quantity'] ?? item['weight'];
    }
    return '0';
  }

  // --- Fungsi Filter & Search Logic ---
  List<dynamic> _getFilteredList() {
    return _laporanList.where((item) {
      final namaSampah = _getItemName(item).toLowerCase();
      final katSampah = _getItemCategory(item);

      bool cocokKategori = false;
      if (_selectedKategori == 'Semua') {
        cocokKategori = true;
      } else if (_selectedKategori == 'Non Organik') {
        cocokKategori = _isNonOrganik(item);
      } else if (_selectedKategori == 'Organik') {
        cocokKategori = _isOrganik(item);
      } else if (_selectedKategori == 'B3') {
        cocokKategori = _isB3(item);
      } else if (_selectedKategori == 'Hasil Olahan') {
        cocokKategori = _isHasilOlahan(item);
      } else {
        cocokKategori = katSampah.toLowerCase().contains(_selectedKategori.toLowerCase());
      }

      final cocokSearch = namaSampah.contains(_searchQuery) || katSampah.toLowerCase().contains(_searchQuery);

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
            child: RefreshIndicator(
              color: primaryColor,
              onRefresh: _fetchLaporan,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryColor))
                  : filteredData.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text("Jenis atau kategori sampah tidak ditemukan")),
                          ],
                        )
                      : _selectedKategori == 'Semua' && _searchQuery.isEmpty
                          ? _buildGroupedListView(filteredData, primaryColor)
                          : _buildNormalListView(filteredData, primaryColor),
            ),
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
    final organikList = data.where((e) => _isOrganik(e)).toList();
    final nonOrganikList = data.where((e) => _isNonOrganik(e)).toList();
    final b3List = data.where((e) => _isB3(e)).toList();
    final olahanList = data.where((e) => _isHasilOlahan(e)).toList();

    // Data yang tidak masuk kategori utama mana pun
    final lainnyaList = data.where((e) => !_isOrganik(e) && !_isNonOrganik(e) && !_isB3(e) && !_isHasilOlahan(e)).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        if (organikList.isNotEmpty) ...[
          _buildCategoryHeader("Sampah Organik", Colors.green),
          ...organikList.map((item) => _buildItemInkWell(item, primaryColor)),
          const SizedBox(height: 10),
        ],
        if (nonOrganikList.isNotEmpty) ...[
          _buildCategoryHeader("Sampah Non-Organik", const Color(0xFFF2994A)),
          ...nonOrganikList.map((item) => _buildItemInkWell(item, primaryColor)),
          const SizedBox(height: 10),
        ],
        if (b3List.isNotEmpty) ...[
          _buildCategoryHeader("Bahan Berbahaya & Beracun (B3)", Colors.redAccent),
          ...b3List.map((item) => _buildItemInkWell(item, primaryColor)),
          const SizedBox(height: 10),
        ],
        if (olahanList.isNotEmpty) ...[
          _buildCategoryHeader("Hasil Olahan", Colors.teal),
          ...olahanList.map((item) => _buildItemInkWell(item, primaryColor)),
          const SizedBox(height: 10),
        ],
        if (lainnyaList.isNotEmpty) ...[
          _buildCategoryHeader("Kategori Lainnya", Colors.blueGrey),
          ...lainnyaList.map((item) => _buildItemInkWell(item, primaryColor)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  // LAYOUT 2: Jika disaring spesifik atau sedang mengetik kolom pencarian
  Widget _buildNormalListView(List<dynamic> data, Color primaryColor) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
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

  String _formatJumlah(dynamic rawJumlah) {
    if (rawJumlah == null) return '0 Kg';
    String str = rawJumlah.toString();
    if (str.isEmpty) return '0 Kg';

    final numericRegex = RegExp(r'^[-+]?\d*\.?\d+$');
    if (numericRegex.hasMatch(str.trim())) {
      final val = double.tryParse(str.trim()) ?? 0.0;
      final displayVal = val % 1 == 0 ? val.toInt().toString() : val.toString();
      return '$displayVal Kg';
    }

    final match = RegExp(r'[-+]?\d*\.?\d+').firstMatch(str);
    if (match != null) {
      final numberStr = match.group(0)!;
      final numberVal = double.tryParse(numberStr) ?? 0.0;
      if (numberVal < 0) {
        final unitPart = str.replaceAll(numberStr, '').trim();
        return '0 ${unitPart.isEmpty ? 'Kg' : unitPart}'.trim();
      }
    }
    return str;
  }

  // Struktur navigasi klik item log kartu
  Widget _buildItemInkWell(dynamic item, Color arrowColor) {
    final mapItem = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map);
    final itemName = _getItemName(mapItem);
    final qtyStr = _formatJumlah(_getItemQuantity(mapItem));

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Stok $itemName: $qtyStr"),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          )
        );
      },
      child: _buildLaporanCard(mapItem, arrowColor),
    );
  }

  Widget _buildLaporanCard(Map<String, dynamic> item, Color arrowColor) {
    bool isBotol = item['isBotol'] == true || item['isBotol'] == 1;
    String name = _getItemName(item);
    String kategoriLabel = _getItemCategory(item);
    dynamic rawJumlah = _getItemQuantity(item);

    IconData cardIcon = Icons.layers_outlined;
    Color iconBgColor = const Color(0xFFE5E9EC);
    Color iconColor = const Color(0xFF14A38B);

    if (_isNonOrganik(item)) {
      if (kategoriLabel == 'Umum') kategoriLabel = 'Non Organik';
      iconBgColor = const Color(0xFFFFF3E0);
      iconColor = const Color(0xFFF2994A);
      cardIcon = isBotol ? Icons.opacity_rounded : Icons.inventory_2_outlined;
    } else if (_isOrganik(item)) {
      if (kategoriLabel == 'Umum') kategoriLabel = 'Organik';
      iconBgColor = const Color(0xFFE8F5E9);
      iconColor = const Color(0xFF2E7D32);
      cardIcon = Icons.grass_rounded;
    } else if (_isB3(item)) {
      if (kategoriLabel == 'Umum') kategoriLabel = 'B3';
      iconBgColor = const Color(0xFFFFEBEE);
      iconColor = const Color(0xFFC62828);
      cardIcon = Icons.warning_amber_rounded;
    } else if (_isHasilOlahan(item)) {
      if (kategoriLabel == 'Umum') kategoriLabel = 'Hasil Olahan';
      iconBgColor = const Color(0xFFE0F2F1);
      iconColor = const Color(0xFF00796B);
      cardIcon = Icons.recycling_rounded;
    }

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
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Center(
              child: Icon(cardIcon, color: iconColor, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name, 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF264653))
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    kategoriLabel, 
                    style: TextStyle(fontSize: 10, color: iconColor, fontWeight: FontWeight.w600)
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
                _formatJumlah(rawJumlah), 
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF264653))
              ),
            ],
          ),
          const SizedBox(width: 10),
          Icon(Icons.info_outline, color: arrowColor, size: 18),
        ],
      ),
    );
  }
}