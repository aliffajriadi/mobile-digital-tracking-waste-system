import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const NotificationCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final itemTitle = data['waste_name'] ?? '-';
    final wasteCode = data['waste_code'] ?? '-';
    final int sisaHari = data['sisa_hari'] ?? 0;
    
    final tglMasuk = DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy').format(tglMasuk);

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    Color bgPastelColor;

    if (sisaHari <= 0) {
      statusColor = const Color(0xFFEF4444);
      bgPastelColor = const Color(0xFFFFEAEB);
      statusLabel = "Masa Simpan Habis (${sisaHari.abs()} hari lalu)";
      statusIcon = Icons.dangerous_rounded;
    } else {
      statusColor = const Color(0xFFFF9F43);
      bgPastelColor = const Color(0xFFFFF7E6);
      statusLabel = "Peringatan: Sisa $sisaHari Hari Lagi!";
      statusIcon = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border(left: BorderSide(color: statusColor, width: 5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: bgPastelColor,
            radius: 20,
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        wasteCode,
                        style: const TextStyle(
                          fontSize: 11, 
                          fontWeight: FontWeight.w800, 
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    Text(
                      "Masuk: $formattedDate",
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  itemTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.w800, 
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}