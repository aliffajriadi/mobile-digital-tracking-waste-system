class UserModel {
  final String nik;
  final String fullName;
  final String email;

  UserModel({
    required this.nik,
    required this.fullName,
    required this.email,
  });

  // Mengubah dari JSON ke Objek Dart
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      nik: json['nik'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}