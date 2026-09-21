import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/app_config.dart';

/// Persisted, role-aware user session.
class SessionData {
  final String token;
  final String role; // 'NASABAH' | 'ADMIN'
  final String username;
  final String? nama; // namaNasabah / namaUnit / namaSiswa
  final String? alamat;
  final String? telp;
  final String? foto;
  final double? saldoPoin;

  const SessionData({
    required this.token,
    required this.role,
    required this.username,
    this.nama,
    this.alamat,
    this.telp,
    this.foto,
    this.saldoPoin,
  });

  bool get isNasabah => role == 'NASABAH';
  bool get isAdmin => role == 'ADMIN';

  Map<String, dynamic> toJson() => {
    'token': token,
    'role': role,
    'username': username,
    'nama': nama,
    'alamat': alamat,
    'telp': telp,
    'foto': foto,
    'saldoPoin': saldoPoin,
  };

  factory SessionData.fromJson(Map<String, dynamic> json) => SessionData(
    token: (json['token'] ?? '') as String,
    role: (json['role'] ?? '') as String,
    username: (json['username'] ?? '') as String,
    nama: json['nama'] as String?,
    alamat: json['alamat'] as String?,
    telp: json['telp'] as String?,
    foto: json['foto'] as String?,
    saldoPoin: (json['saldoPoin'] as num?)?.toDouble(),
  );
}

/// Central store for the app key, JWT, and current user session.
///
/// - JWT + session live in flutter_secure_storage (encrypted on device).
/// - The appKey also lives in secure storage; a build-time default may be
///   provided through --dart-define but is never committed in source.
class SessionController {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kSession = 'ukk_session';

  /// In-memory mirror so sync getters are cheap during a frame.
  SessionData? _current;

  SessionData? get current => _current;

  /// JWT for authenticated API calls (from in-memory session or secure storage).
  Future<String?> get token async {
    if (_current != null) return _current!.token;
    final loaded = await load();
    return loaded?.token;
  }

  // ---- app key ----

  Future<String?> get appKey async {
    return AppConfig.appKey.isEmpty ? null : AppConfig.appKey;
  }

  // ---- session ----

  Future<SessionData?> load() async {
    final raw = await _storage.read(key: _kSession);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        _current = SessionData.fromJson(map);
        return _current;
      }
    } catch (_) {
      await _storage.delete(key: _kSession);
    }
    return null;
  }

  Future<void> saveSession(SessionData data) async {
    _current = data;
    await _storage.write(key: _kSession, value: jsonEncode(data.toJson()));
  }

  /// Clears JWT + user session (logout or 401). The app key is intentionally
  /// kept so the user does not have to re-enter the tenant key after logout.
  Future<void> clearSession() async {
    _current = null;
    await _storage.delete(key: _kSession);
  }

  /// Wipes app key + session (used by "reset aplikasi" in settings).
  Future<void> wipeAll() async {
    _current = null;
    await _storage.delete(key: _kSession);
  }

  Future<void> updateSaldo(double saldo) async {
    final s = _current;
    if (s == null) return;
    await saveSession(
      SessionData(
        token: s.token,
        role: s.role,
        username: s.username,
        nama: s.nama,
        alamat: s.alamat,
        telp: s.telp,
        foto: s.foto,
        saldoPoin: saldo,
      ),
    );
  }
}

/// Small typed wrapper for admin-registered unit profile shown on Profil Unit.
class AdminBankProfile {
  final String? namaUnit;
  final String? namaPengelola;
  final String? telp;
  const AdminBankProfile({this.namaUnit, this.namaPengelola, this.telp});
}
