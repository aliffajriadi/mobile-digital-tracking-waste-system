class DashboardSummary {
  final int totalMasuk;
  final int sampahKeluar;
  final int sudahDiolah;

  const DashboardSummary({
    required this.totalMasuk,
    required this.sampahKeluar,
    required this.sudahDiolah,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalMasuk: json['total_masuk'] ?? 0,
      sampahKeluar: json['sampah_keluar'] ?? 0,
      sudahDiolah: json['sudah_diolah'] ?? 0,
    );
  }
}