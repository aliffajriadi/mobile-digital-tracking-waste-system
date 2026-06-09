class ApiConstants {
  // 1. Alamat Host Utama (Cukup ubah IP di sini jika laptop ganti Wi-Fi)
  static const String host = 'http://192.168.1.8:8000';

  // 2. Base URL untuk Endpoint API & Storage File
  // (Ditambahkan ApiConstants.host agar Dart tidak bingung dan tidak error)
  static const String baseUrl = '$host/api';
  static const String storageUrl = '$host/storage';

  // 3. KUMPULAN ENDPOINT GLOBAL
  // Autentikasi & Akun
  static const String login = '$baseUrl/login';
  static const String changePassword = '$baseUrl/change-password';
  static const String updateProfile = '$baseUrl/update-profile';

  // Dashboard & Dropdown Master Data
  static const String dashboardData = '$baseUrl/dashboard-data'; 
  static const String categories = '$baseUrl/categories';
  static const String subCategories = '$baseUrl/sub-categories'; 
  static const String kategoriKendala = '$baseUrl/kategori-kendala';
  static const String sourceLocations = '$baseUrl/source-locations';

  // Transaksi Sampah
  static const String wasteEntry = '$baseUrl/waste-entry';

  // Fitur Laporan & Riwayat
  static const String riwayatLaporan = '$baseUrl/riwayat-laporan'; 
  static const String laporanHarian = '$baseUrl/laporan-harian'; 
  static const String laporanKendala = '$baseUrl/laporan-kendala'; 

  static const String processedWaste = '$baseUrl/processed-waste';
  static const String processedWasteData = '$baseUrl/processed-waste-data';

  static const String wasteOutMethods = '$baseUrl/waste-out-methods';
  static const String wasteOut = '$baseUrl/waste-out';

  static const String wasteB3Notifications = '$baseUrl/waste-b3-notifications';
}