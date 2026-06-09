import 'package:flutter/material.dart';

class DashboardSummaryCard extends StatelessWidget {
  final int totalMasuk;
  final int sampahKeluar;
  final int sudahDiolah;

  const DashboardSummaryCard({
    super.key,
    required this.totalMasuk,
    required this.sampahKeluar,
    required this.sudahDiolah,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Hari Ini',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              _buildItem(
                label: "Total Masuk",
                value: "$totalMasuk Tx",
                color: primaryColor,
                background: primaryColor.withOpacity(0.06),
              ),

              const SizedBox(width: 6),

              _buildItem(
                label: "Sudah Diolah",
                value: "$sudahDiolah Tx",
                color: const Color(0xFFD97706),
                background: Colors.amber.withOpacity(0.07),
              ),

              const SizedBox(width: 6),

              _buildItem(
                label: "Sampah Keluar",
                value: "$sampahKeluar Tx",
                color: Colors.blue,
                background: Colors.blue.withOpacity(0.06),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildItem({
    required String label,
    required String value,
    required Color color,
    required Color background,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}