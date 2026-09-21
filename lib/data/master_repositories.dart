import 'dart:io' show File;

import 'package:sampahbank/core/exceptions.dart';
import 'package:sampahbank/data/models/models.dart';

import '../../core/api_client.dart';
import '../../core/app_config.dart';

/// Master data repositories: kategori sampah, hadiah, dan nasabah (admin).
/// Each supports optional photo upload via multipart.

// ---------------------------------------------------------------------------
// Kategori sampah
// ---------------------------------------------------------------------------

class KategoriRepository {
  final ApiClient api;
  KategoriRepository(this.api);

  /// GET /api/v1/kategori-sampah (nasabah & admin, no Bearer required).
  Future<List<KategoriSampah>> list() async {
    final res = await api.get(AppConfig.epKategoriSampah);
    return _mapList(res.data, KategoriSampah.fromJson);
  }

  /// GET /api/v1/kategori-sampah/{id}
  Future<KategoriSampah> detail(String id) async {
    final res = await api.get('${AppConfig.epKategoriSampah}/$id');
    return KategoriSampah.fromJson(_asMap(res.data));
  }

  /// POST /api/v1/kategori-sampah (admin, multipart with optional foto).
  Future<ApiResponse<dynamic>> create({
    required String namaKategori,
    required double hargaPerKg,
    required double poinPerKg,
    required String jenis,
    String? fotoPath,
  }) {
    final fields = {
      'namaKategori': namaKategori,
      'hargaPerKg': _num(hargaPerKg),
      'poinPerKg': _num(poinPerKg),
      'jenis': jenis,
    };
    return _send(AppConfig.epKategoriSampah, 'post', fields, fotoPath);
  }

  /// PUT /api/v1/kategori-sampah/{id}
  Future<ApiResponse<dynamic>> update(
    String id, {
    required String namaKategori,
    required double hargaPerKg,
    required double poinPerKg,
    required String jenis,
    String? fotoPath,
  }) {
    final fields = {
      'namaKategori': namaKategori,
      'hargaPerKg': _num(hargaPerKg),
      'poinPerKg': _num(poinPerKg),
      'jenis': jenis,
    };
    return _send('${AppConfig.epKategoriSampah}/$id', 'put', fields, fotoPath);
  }

  /// DELETE /api/v1/kategori-sampah/{id}
  Future<ApiResponse<dynamic>> delete(String id) =>
      api.delete('${AppConfig.epKategoriSampah}/$id');

  Future<ApiResponse<dynamic>> _send(
    String path,
    String method,
    Map<String, String> fields,
    String? fotoPath,
  ) {
    if (fotoPath == null || fotoPath.isEmpty || !File(fotoPath).existsSync()) {
      return method == 'post'
          ? api.post(path, body: fields)
          : api.put(path, body: fields);
    }
    return api.sendMultipart(
      method: method,
      path: path,
      fields: fields,
      file: XFile(fotoPath),
    );
  }
}

// ---------------------------------------------------------------------------
// Hadiah
// ---------------------------------------------------------------------------

class HadiahRepository {
  final ApiClient api;
  HadiahRepository(this.api);

  /// GET /api/v1/hadiah
  Future<List<Hadiah>> list() async {
    final res = await api.get(AppConfig.epHadiah);
    return _mapList(res.data, Hadiah.fromJson);
  }

  /// GET /api/v1/hadiah/{id}
  Future<Hadiah> detail(String id) async {
    final res = await api.get('${AppConfig.epHadiah}/$id');
    return Hadiah.fromJson(_asMap(res.data));
  }

  /// POST /api/v1/hadiah (multipart with optional foto).
  Future<ApiResponse<dynamic>> create({
    required String namaHadiah,
    required double poinDibutuhkan,
    required int stok,
    String? fotoPath,
  }) {
    final fields = {
      'namaHadiah': namaHadiah,
      'poinDibutuhkan': _num(poinDibutuhkan),
      'stok': '$stok',
    };
    return _send(AppConfig.epHadiah, 'post', fields, fotoPath);
  }

  /// PUT /api/v1/hadiah/{id}
  Future<ApiResponse<dynamic>> update(
    String id, {
    required String namaHadiah,
    required double poinDibutuhkan,
    required int stok,
    String? fotoPath,
  }) {
    final fields = {
      'namaHadiah': namaHadiah,
      'poinDibutuhkan': _num(poinDibutuhkan),
      'stok': '$stok',
    };
    return _send('${AppConfig.epHadiah}/$id', 'put', fields, fotoPath);
  }

  /// DELETE /api/v1/hadiah/{id}
  Future<ApiResponse<dynamic>> delete(String id) =>
      api.delete('${AppConfig.epHadiah}/$id');

  Future<ApiResponse<dynamic>> _send(
    String path,
    String method,
    Map<String, String> fields,
    String? fotoPath,
  ) {
    if (fotoPath == null || fotoPath.isEmpty || !File(fotoPath).existsSync()) {
      return method == 'post'
          ? api.post(path, body: fields)
          : api.put(path, body: fields);
    }
    return api.sendMultipart(
      method: method,
      path: path,
      fields: fields,
      file: XFile(fotoPath),
    );
  }
}

// ---------------------------------------------------------------------------
// Admin: CRUD nasabah
// ---------------------------------------------------------------------------

class NasabahAdminRepository {
  final ApiClient api;
  NasabahAdminRepository(this.api);

  /// GET /api/v1/admin/nasabah
  Future<List<NasabahAdmin>> list() async {
    final res = await api.get(AppConfig.epAdminNasabah);
    return _mapList(res.data, NasabahAdmin.fromJson);
  }

  /// GET /api/v1/admin/nasabah/{id}
  Future<NasabahAdmin> detail(String id) async {
    final res = await api.get('${AppConfig.epAdminNasabah}/$id');
    return NasabahAdmin.fromJson(_asMap(res.data));
  }

  /// POST /api/v1/admin/nasabah (multipart with optional foto).
  Future<ApiResponse<dynamic>> create({
    required String username,
    required String password,
    required String namaNasabah,
    required String alamat,
    required String telp,
    String? fotoPath,
  }) {
    final fields = {
      'username': username,
      'password': password,
      'namaNasabah': namaNasabah,
      'alamat': alamat,
      'telp': telp,
    };
    return _send(AppConfig.epAdminNasabah, 'post', fields, fotoPath);
  }

  /// PUT /api/v1/admin/nasabah/{id} using UpdateNasabahDto.
  /// Username/password are not updated here.
  Future<ApiResponse<dynamic>> update(
    String id, {
    required String namaLengkap,
    required String alamat,
    required String noTelepon,
    required String tanggalLahir,
    String? fotoPath,
  }) {
    final fields = {
      'namaLengkap': namaLengkap,
      'noTelepon': noTelepon,
      'alamat': alamat,
      'tanggalLahir': tanggalLahir,
    };
    final path = '${AppConfig.epAdminNasabah}/$id';
    final hasFoto =
        fotoPath != null && fotoPath.isNotEmpty && File(fotoPath).existsSync();

    if (hasFoto) {
      return api.sendMultipart(
        method: 'put',
        path: path,
        fields: fields,
        file: XFile(fotoPath),
      );
    }
    return api.put(path, body: fields);
  }

  /// DELETE /api/v1/admin/nasabah/{id}
  Future<ApiResponse<dynamic>> delete(String id) =>
      api.delete('${AppConfig.epAdminNasabah}/$id');

  Future<ApiResponse<dynamic>> _send(
    String path,
    String method,
    Map<String, String> fields,
    String? fotoPath, {
    bool forceMultipart = false,
  }) {
    if (!forceMultipart &&
        (fotoPath == null ||
            fotoPath.isEmpty ||
            !File(fotoPath).existsSync())) {
      return method == 'post'
          ? api.post(path, body: fields)
          : api.put(path, body: fields);
    }
    return api.sendMultipart(
      method: method,
      path: path,
      fields: fields,
      file: fotoPath == null || fotoPath.isEmpty || !File(fotoPath).existsSync()
          ? null
          : XFile(fotoPath),
    );
  }
}

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

String _num(num v) {
  final d = v.toDouble();
  return d == d.truncateToDouble() ? d.toInt().toString() : d.toString();
}

List<T> _mapList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }
  throw ApiException('Data yang diterima bukan berupa daftar.');
}

Map<String, dynamic> _asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  throw ApiException('Struktur data dari server tidak sesuai kontrak.');
}
