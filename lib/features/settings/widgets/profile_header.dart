import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String nik;
  final String? imageUrl;
  final VoidCallback onPhotoTap;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.nik,
    required this.imageUrl,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);

    return Transform.translate(
      offset: const Offset(0, -30),
      child: Column(
        children: [
          GestureDetector(
            onTap: onPhotoTap,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
                    child: imageUrl == null
                        ? const Icon(Icons.person, size: 55, color: Colors.grey)
                        : null,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name.isEmpty ? 'Nama Karyawan' : name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE2F9F3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'NIK : $nik',
              style: const TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}