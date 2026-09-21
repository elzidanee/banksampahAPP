/// Reusable form validators (UKK: clear, human-readable validation).
class Validators {
  Validators._();

  static String? required(String? v, {String label = 'Kolom ini'}) {
    if (v == null || v.trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  static String? username(String? v) {
    final r = required(v, label: 'Username');
    if (r != null) return r;
    if (v!.trim().contains(' ')) return 'Username tidak boleh mengandung spasi';
    return null;
  }

  /// Contract: password min 6 characters (RegisterAppMakerDto note applies to
  /// all password DTOs in the PDF).
  static String? password(String? v) {
    final r = required(v, label: 'Password');
    if (r != null) return r;
    if (v!.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  static String? confirmPassword(String? v, String? original) {
    final r = required(v, label: 'Konfirmasi password');
    if (r != null) return r;
    if (v != original) return 'Konfirmasi password tidak sama';
    return null;
  }

  static String? phone(String? v) {
    final r = required(v, label: 'No. telepon');
    if (r != null) return r;
    final digits = v!.replaceAll(RegExp(r'[\s\-+]'), '');
    if (!RegExp(r'^\d{8,15}$').hasMatch(digits)) {
      return 'No. telepon tidak valid (8–15 digit angka)';
    }
    return null;
  }

  static String? positiveNumber(String? v, {String label = 'Nilai'}) {
    final r = required(v, label: label);
    if (r != null) return r;
    final parsed = double.tryParse(v!.trim().replaceAll(',', '.'));
    if (parsed == null) return '$label harus berupa angka';
    if (parsed <= 0) return '$label harus lebih dari 0';
    return null;
  }

  static String? nonNegativeInt(String? v, {String label = 'Nilai'}) {
    final r = required(v, label: label);
    if (r != null) return r;
    final parsed = int.tryParse(v!.trim());
    if (parsed == null) return '$label harus berupa angka bulat';
    if (parsed < 0) return '$label tidak boleh negatif';
    return null;
  }
}
