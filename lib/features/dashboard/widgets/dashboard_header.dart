import 'package:flutter/material.dart';

import '../../../core/constants/api_constants.dart';
import '../../settings/pages/notification_page.dart';

class DashboardHeader extends StatelessWidget {
  final String namaPetugas;
  final String? fotoProfil;

  const DashboardHeader({
    super.key,
    required this.namaPetugas,
    required this.fotoProfil,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 35,
        bottom: 20,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFFFB057),
              shape: BoxShape.circle,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: fotoProfil != null && fotoProfil!.isNotEmpty
                  ? Image.network(
                      "${ApiConstants.baseUrl}/storage/$fotoProfil",
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 28,
                        );
                      },
                    )
                  : const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hallo, $namaPetugas",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Petugas Rumah Sampah",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotifikasiPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}