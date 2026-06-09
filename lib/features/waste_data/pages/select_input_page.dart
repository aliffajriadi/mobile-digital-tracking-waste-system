import 'package:flutter/material.dart';
import '../widgets/waste_type_card.dart';
import '../../waste_entry/pages/category_waste.dart';
import '../../processed_waste/pages/processed_method.dart';
import '../../report/pages/report_submiss.dart';
import '../../waste_out/pages/method_out.dart';

class SelectInputPage extends StatelessWidget {
  final String? jenisSampah;

  const SelectInputPage({super.key, this.jenisSampah});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);
    const bgLightColor = Color(0xFFF4F7F9);

    return Scaffold(
      backgroundColor: bgLightColor,
      appBar: _buildAppBar(primaryColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Silakan pilih jenis pencatatan sampah yang ingin dilaporkan:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF264653),
                ),
              ),
            ),
            const SizedBox(height: 20),

            WasteTypeCard(
              title: 'Sampah Masuk',
              description:
                  'Catat berat timbangan sampah harian yang baru tiba di rumah sampah.',
              startColor: const Color(0xFF02AAB0),
              endColor: const Color(0xFF00CDAC),
              icon: Icons.login_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PilihKategoriPage(),
                  ),
                );
              },
            ),

            WasteTypeCard(
              title: 'Olahan Sampah',
              description:
                  'Catat hasil sampah yang berhasil diolah kembali (kompos, pupuk cair, kerajinan).',
              startColor: const Color(0xFF3A9D8F),
              endColor: const Color(0xFF2A7B6F),
              icon: Icons.recycling_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LaporanOlahanPage(),
                  ),
                );
              },
            ),

            WasteTypeCard(
              title: 'Sampah Keluar / Residu',
              description:
                  'Catat sampah sisa yang dibawa ke TPA.',
              startColor: const Color(0xFF8A5A16),
              endColor: const Color(0xFF70450D),
              icon: Icons.logout_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PilihMetodeKeluarPage(),
                  ),
                );
              },
            ),

            WasteTypeCard(
              title: 'Lainnya / Kendala',
              description:
                  'Laporkan kendala operasional di lapangan.',
              startColor: const Color(0xFFE07A5F),
              endColor: const Color(0xFFD95D39),
              icon: Icons.report_problem_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LaporanKendalaPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Color primaryColor) {
    return AppBar(
      toolbarHeight: 80,
      backgroundColor: primaryColor,
      elevation: 0,
      leading: const BackButton(color: Colors.white),
      title: const Padding(
        padding: EdgeInsets.only(top: 0),
        child: Text(
          'Pilih Aktivitas Laporan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}