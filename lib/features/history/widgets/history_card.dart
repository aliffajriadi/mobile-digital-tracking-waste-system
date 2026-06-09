import 'package:flutter/material.dart';
import '../pages/detail_waste_page.dart'; 

class HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const HistoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final String tipe = (item['type_log'] ?? '').toString();
    const darkBlueColor = Color(0xFF264653);

    IconData icon = Icons.assignment;
    Color statusColor = Colors.grey;
    Color bgCircleColor = Colors.grey.shade100;

    if (tipe == 'input_masuk') {
      icon = Icons.download_rounded;
      statusColor = const Color(0xFF14A38B);
      bgCircleColor = const Color(0xFFE2F9F3);
    } else if (tipe == 'input_keluar') {
      icon = Icons.upload_rounded;
      statusColor = const Color(0xFFFF9F43);
      bgCircleColor = const Color(0xFFFFF7E6);
    } else if (tipe == 'olahan') {
      icon = Icons.precision_manufacturing_rounded;
      statusColor = const Color(0xFF2196F3);
      bgCircleColor = const Color(0xFFE3F2FD);
    } else if (tipe == 'kendala') {
      icon = Icons.warning_amber_rounded;
      statusColor = const Color(0xFFEF4444);
      bgCircleColor = const Color(0xFFFFEAEB);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          final int? parsedId = item['id_laporan'] != null 
              ? int.tryParse(item['id_laporan'].toString()) 
              : null;

          if (parsedId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("ID laporan tidak valid atau kosong")),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailLaporanPage(idLaporan: parsedId),
            ),
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Lingkaran Ikon Status Log
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgCircleColor, 
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              
              // Konten Tengah (Judul Log & Jam)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: darkBlueColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['time'] ?? '-',
                      style: const TextStyle(
                        fontSize: 12, 
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // Informasi Kuantitas / Jumlah Satuan di Sisi Kanan
              Row(
                children: [
                  Text(
                    item['amount'] ?? '-',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}