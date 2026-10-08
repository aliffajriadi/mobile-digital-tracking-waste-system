import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _faqs = [
    (
      'Akun & Login',
      [
        ('Saya lupa kata sandi, bagaimana?', 'Hubungi admin. Admin dapat mereset kata sandi Anda dari panel web, lalu Anda bisa langsung login dengan kata sandi baru.'),
        ('Kenapa saya tiba-tiba keluar dari aplikasi?', 'Sesi berakhir jika admin menonaktifkan akun, mereset kata sandi, atau Anda mengganti kata sandi dari perangkat lain. Silakan login kembali.'),
      ]
    ),
    (
      'Pencatatan Sampah',
      [
        ('Kenapa sampah keluar/olahan saya ditolak karena stok?', 'Jumlah yang dikeluarkan atau diolah tidak boleh melebihi stok gudang. Periksa menu Stok, lalu pastikan sampah masuk sudah dicatat terlebih dahulu.'),
        ('Saya mencatat transaksi kemarin, bisa?', 'Bisa. Ubah kolom Waktu pada form ke tanggal & jam sebenarnya. Waktu di masa depan tidak diizinkan.'),
        ('Saya salah menginput jumlah, bagaimana memperbaikinya?', 'Buka Riwayat, pilih transaksinya, lalu ketuk "Ada kesalahan data? Laporkan ke admin". Admin akan memperbaiki data tersebut.'),
        ('Boleh memakai koma untuk angka desimal?', 'Boleh. 1,5 dan 1.5 sama-sama dibaca sebagai satu setengah.'),
      ]
    ),
    (
      'Timbangan IoT & B3',
      [
        ('Bagaimana menghubungkan timbangan?', 'Buka Akun › Timbangan IoT, lalu masukkan 4 karakter kode yang tampil di layar timbangan.'),
        ('Apa arti peringatan limbah B3?', 'Limbah B3 di gudang mendekati atau melewati batas masa simpan. Segera serahkan ke pihak berizin lalu catat sebagai Sampah Keluar.'),
      ]
    ),
    (
      'Kendala Aplikasi',
      [
        ('Muncul pesan "Tidak ada koneksi internet"', 'Pastikan data seluler/Wi-Fi aktif, lalu tarik layar ke bawah untuk memuat ulang. Data yang belum tersimpan tidak hilang selama Anda tidak menutup form.'),
        ('Ingin menambah jenis sampah atau metode keluar baru?', 'Data master (kategori, jenis sampah, metode keluar, pembeli) dikelola admin melalui panel web.'),
      ]
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pusat Bantuan')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
        for (final section in _faqs) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8),
            child: Text(section.$1.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.8)),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (var i = 0; i < section.$2.length; i++) ...[
                if (i > 0) const Divider(),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    iconColor: AppColors.primary,
                    title: Text(section.$2[i].$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedAlignment: Alignment.centerLeft,
                    children: [Text(section.$2[i].$2, style: const TextStyle(color: AppColors.inkSoft, height: 1.5, fontSize: 13))],
                  ),
                ),
              ],
            ]),
          ),
        ],
        const SizedBox(height: 20),
        Card(
          color: AppColors.primarySoft,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(children: [
              Icon(Icons.support_agent_rounded, color: AppColors.primaryDark),
              SizedBox(width: 12),
              Expanded(child: Text('Masih butuh bantuan? Kirim Laporan Kendala dari tombol Catat, admin akan menindaklanjuti.', style: TextStyle(fontSize: 13, height: 1.4))),
            ]),
          ),
        ),
      ]),
    );
  }
}
