import 'package:flutter/material.dart';

class FilterBottomSheet extends StatelessWidget {
  final List<dynamic> categories;
  final int? selectedCategoryId;
  final Function(int? id, String name) onCategorySelected;

  const FilterBottomSheet({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);
    const darkBlueColor = Color(0xFF264653);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Garis Indicator kecil penanda modal bisa di-swipe down
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "Filter Berdasarkan Kategori",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkBlueColor,
            ),
          ),
          const SizedBox(height: 12),
          
          // Opsi Manual untuk Menampilkan Semua Data Kategori
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              "Semua Kategori",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkBlueColor),
            ),
            trailing: selectedCategoryId == null
                ? const Icon(Icons.check_circle_rounded, color: primaryColor, size: 22)
                : null,
            onTap: () => onCategorySelected(null, "Semua"),
          ),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),

          // Daftar Looping Kategori Dinamis dari API
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                if (cat['id'] == '') return const SizedBox.shrink();

                final int? currentId = cat['id'] != null ? int.tryParse(cat['id'].toString()) : null;
                final String categoryName = cat['name'].toString();

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    categoryName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: darkBlueColor),
                  ),
                  trailing: selectedCategoryId == currentId
                      ? const Icon(Icons.check_circle_rounded, color: primaryColor, size: 22)
                      : null,
                  onTap: () => onCategorySelected(currentId, categoryName),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}