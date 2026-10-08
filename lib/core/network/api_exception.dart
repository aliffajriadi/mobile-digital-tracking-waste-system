class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>> errors;

  const ApiException(this.message, {this.statusCode, this.errors = const {}});

  bool get isUnauthorized => statusCode == 401;
  bool get isValidation => statusCode == 422;
  bool get isNetwork => statusCode == null;

  /// Pesan error pertama untuk field tertentu (mis. 'measured_qty').
  String? fieldError(String field) {
    for (final entry in errors.entries) {
      if (entry.key == field || entry.key.startsWith('$field.')) {
        return entry.value.isNotEmpty ? entry.value.first : null;
      }
    }
    return null;
  }

  /// Semua pesan validasi digabung (untuk ditampilkan dalam satu dialog).
  String get fullMessage {
    final all = errors.values.expand((e) => e).toSet().toList();
    if (all.isEmpty) return message;
    return all.join('\n');
  }

  @override
  String toString() => message;
}
