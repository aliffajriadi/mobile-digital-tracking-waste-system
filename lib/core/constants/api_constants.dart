class ApiConstants {
  ApiConstants._();

  // Alamat host utama. Untuk server lokal jalankan:
  // flutter run --dart-define=API_HOST=http://192.168.1.10:8000
  static const String host = String.fromEnvironment('API_HOST', defaultValue: 'https://pbl.anjay.fun');

  static const String baseUrl = '$host/api';
  static const String storageUrl = '$host/storage';

  // Autentikasi & Akun
  static const String login = '$baseUrl/login';
  static const String logout = '$baseUrl/logout';
  static const String me = '$baseUrl/user';
  static const String changePassword = '$baseUrl/change-password';
  static const String updateProfile = '$baseUrl/update-profile';

  // Dashboard & Data Master
  static const String dashboardData = '$baseUrl/dashboard-data';
  static const String categories = '$baseUrl/categories';
  static const String subCategories = '$baseUrl/sub-categories';
  static const String kategoriKendala = '$baseUrl/kategori-kendala';
  static const String sourceLocations = '$baseUrl/source-locations';

  // Transaksi Sampah
  static const String wasteEntry = '$baseUrl/waste-entry';
  static const String processedWaste = '$baseUrl/processed-waste';
  static const String processedWasteData = '$baseUrl/processed-waste-data';
  static const String wasteOutMethods = '$baseUrl/waste-out-methods';
  static const String wasteOut = '$baseUrl/waste-out';
  static const String wasteBuyers = '$baseUrl/waste-buyers';
  static const String wasteDestinations = '$baseUrl/waste-destinations';

  // Laporan & Riwayat
  static const String riwayatLaporan = '$baseUrl/riwayat-laporan';
  static const String laporanHarian = '$baseUrl/laporan-harian';
  static const String wasteStocks = '$baseUrl/waste-stocks';
  static const String laporanKendala = '$baseUrl/laporan-kendala';
  static const String wasteB3Notifications = '$baseUrl/waste-b3-notifications';

  // IoT
  static const String iotSession = '$baseUrl/iot/session';
  static const String iotPair = '$baseUrl/iot/pair';
  static const String iotUnpair = '$baseUrl/iot/unpair';

  /// Ubah path relatif dari server (mis. "user_photos/a.jpg") menjadi URL lengkap.
  static String? fileUrl(dynamic pathOrUrl) {
    final value = pathOrUrl?.toString() ?? '';
    if (value.isEmpty) return null;
    if (value.startsWith('http')) return value;
    return '$storageUrl/$value';
  }
}
