class UserModel {
  final int id;
  final String nik;
  final String fullName;
  final String email;

  UserModel({
    required this.id,
    required this.nik,
    required this.fullName,
    required this.email,
  });

  // Mengubah dari JSON ke Objek Dart
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      nik: json['nik'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}