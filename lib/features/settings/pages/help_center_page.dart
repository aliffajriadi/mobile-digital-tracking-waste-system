import 'package:flutter/material.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B); 

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Pusat Bantuan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER SEARCH BAR
            _buildHeaderSearch(primaryColor),

            const SizedBox(height: 25),

            // 2. SEKSI KATEGORI UTAMA
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Kategori Bantuan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF264653))),
            ),
            const SizedBox(height: 12),
            _buildCategoryGrid(primaryColor),

            const SizedBox(height: 30),

            // 3. SEKSI FAQ (Pertanyaan Sering Diajukan)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Pertanyaan Populer (FAQ)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF264653))),
            ),
            const SizedBox(height: 12),
            _buildFaqList(primaryColor),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGET KOMPONEN 1: SEARCH HEADER ---
  Widget _buildHeaderSearch(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Halo, ada yang bisa kami bantu?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 15),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari masalah atau panduan...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET KOMPONEN 2: GRID KATEGORI ---
  Widget _buildCategoryGrid(Color color) {
    final List<Map<String, dynamic>> categories = [
      {'icon': Icons.lock_outline, 'title': 'Akun & Login'},
      {'icon': Icons.assignment_outlined, 'title': 'Input Sampah'},
      {'icon': Icons.analytics_outlined, 'title': 'Data Olahan'},
      {'icon': Icons.gpp_maybe_outlined, 'title': 'Error Aplikasi'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.4,
        ),
        itemBuilder: (context, idx) {
          final cat = categories[idx];
          return Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Arahkan ke sub-kategori spesifik
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(cat['icon'], color: color, size: 32),
                    const SizedBox(height: 8),
                    Text(cat['title'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF264653))),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET KOMPONEN 3: EXPANSION TILE FAQ ---
  Widget _buildFaqList(Color color) {
    final List<Map<String, String>> faqs = [
      {
        'q': 'Bagaimana jika salah menginput jumlah (kg) sampah?',
        'a': 'Anda dapat membuka menu Riwayat, pilih transaksi yang salah, lalu klik tombol "Ajukan Edit" jika data belum dikunci oleh Admin.'
      },
      {
        'q': 'Aplikasi muncul error status 404/500, apa solusinya?',
        'a': 'Pastikan koneksi internet ponsel stabil. Jika masalah berlanjut, hubungi tim IT untuk memeriksa apakah server backend sedang maintenance.'
      },
      {
        'q': 'Bagaimana cara menambahkan metode baru di menu sampah keluar?',
        'a': 'Penambahan metode keluar (misal: dijual, dibakar, dibuang) hanya bisa dilakukan oleh manajemen melalui Dashboard Admin Web.'
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: faqs.length,
        itemBuilder: (context, idx) {
          return Card(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: color,
                collapsedIconColor: Colors.grey,
                title: Text(faqs[idx]['q']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF264653))),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Text(faqs[idx]['a']!, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4)),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}