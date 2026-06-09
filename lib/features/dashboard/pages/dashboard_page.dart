import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/features/waste_entry/pages/subcategory_waste.dart';

import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_summary_card.dart';
import '../widgets/waste_category_card.dart';
import '../widgets/recent_entry_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _namaPetugas = "Memuat...";
  String? _fotoProfil;

  List<dynamic> _kategoriSampah = [];
  List<dynamic> _riwayatHariIni = [];

  int _totalMasuk = 0;
  int _sampahKeluar = 0;
  int _sudahDiolah = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      if (!mounted) return;

      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(ApiConstants.dashboardData),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _namaPetugas = data['full_name'] ?? '';
          _fotoProfil = data['user_photo'];

          _kategoriSampah = data['categories'] ?? [];
          _riwayatHariIni = data['recent_entries'] ?? [];

          _totalMasuk =
              data['today_summary']?['total_masuk'] ?? 0;

          _sampahKeluar =
              data['today_summary']?['sampah_keluar'] ?? 0;

          _sudahDiolah =
              data['today_summary']?['sudah_diolah'] ?? 0;

          _isLoading = false;
        });
      } else {
        setState(() {
          _namaPetugas = data['message'] ?? 'Gagal memuat data';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _namaPetugas = 'Gagal Terhubung';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getStyleKategori(String name) {
    final lowerName = name.toLowerCase();

    if (lowerName.contains('organik') &&
        !lowerName.contains('anorganik')) {
      return {
        'color': const Color(0xFF14A38B),
        'icon': Icons.grass_rounded,
      };
    }

    if (lowerName.contains('anorganik') ||
        lowerName.contains('non organik')) {
      return {
        'color': const Color(0xFFF2994A),
        'icon': Icons.layers_outlined,
      };
    }

    if (lowerName.contains('b3')) {
      return {
        'color': const Color(0xFFEB5757),
        'icon': Icons.gpp_maybe_outlined,
      };
    }

    return {
      'color': Colors.blueGrey,
      'icon': Icons.delete_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                color: primaryColor,
              ),

              SafeArea(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    DashboardHeader(
                      namaPetugas: _namaPetugas,
                      fotoProfil: _fotoProfil,
                    ),

                    DashboardSummaryCard(
                      totalMasuk: _totalMasuk,
                      sampahKeluar: _sampahKeluar,
                      sudahDiolah: _sudahDiolah,
                    ),

                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lapor Sampah Harian Sekarang',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (_isLoading)
                            const Center(
                              child:
                                  CircularProgressIndicator(),
                            )
                          else if (_kategoriSampah.isEmpty)
                            const Text(
                              'Kategori tidak tersedia.',
                            )
                          else
                            Column(
                              children:
                                  _kategoriSampah.map((item) {
                                final style =
                                    _getStyleKategori(
                                  item['name'] ?? '',
                                );

                                return WasteCategoryCard(
                                  title:
                                      item['name'] ?? '',
                                  description:
                                      item['description'] ??
                                          '',
                                  color: style['color'],
                                  icon: style['icon'],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            SubCategoryPage(
                                          category: item,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),

                          const SizedBox(height: 24),

                          const Text(
                            'Riwayat Hari Ini',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (_isLoading)
                            const Center(
                              child:
                                  CircularProgressIndicator(),
                            )
                          else if (_riwayatHariIni.isEmpty)
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(
                                        12),
                              ),
                              child: const Text(
                                'Belum ada data yang diinput hari ini',
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount:
                                  _riwayatHariIni.length,
                              itemBuilder:
                                  (context, index) {
                                final item =
                                    _riwayatHariIni[index];

                                return RecentEntryCard(
                                  categoryName:
                                      item['sub_category']
                                              ?['name'] ??
                                          'Sampah',
                                  locationName:
                                      item['source_location']
                                              ?['name'] ??
                                          'Lokasi',
                                  quantity:
                                      item['measured_qty']
                                              ?.toString() ??
                                          '0',
                                  unit: item[
                                                  'sub_category']
                                              ?[
                                              'unit_measured']
                                          ?['symbol'] ??
                                      'Kg',
                                );
                              },
                            ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}