import 'dart:io' show File;

import 'package:sampahbank/core/exceptions.dart';
import 'package:sampahbank/data/models/models.dart';

import '../../core/api_client.dart';
import '../../core/app_config.dart';

/// Repository for every auth-related endpoint.
class AuthRepository {
  final ApiClient api;
  AuthRepository(this.api);

  /// POST /api/v1/auth/nasabah/register (multipart when foto chosen).
  Future<ApiResponse<dynamic>> registerNasabah({
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
    return _withPhotoIfAny(AppConfig.epAuthNasabahRegister, fields, fotoPath);
  }

  /// POST /api/v1/auth/admin/register — JSON body (no photo in contract).
  Future<ApiResponse<dynamic>> registerAdmin({
    required String username,
    required String password,
    required String namaUnit,
    required String namaPengelola,
    required String telp,
  }) {
    return api.post(
      AppConfig.epAuthAdminRegister,
      body: {
        'username': username,
        'password': password,
        'namaUnit': namaUnit,
        'namaPengelola': namaPengelola,
        'telp': telp,
      },
    );
  }

  /// POST /api/v1/auth/login — returns [UserProfile] + token via envelope.
  Future<(UserProfile, String)> login({
    required String username,
    required String password,
  }) async {
    final res = await api.post(
      AppConfig.epAuthLogin,
      body: {'username': username, 'password': password},
    );
    final data = _asMap(res.data);
    final user = UserProfile.fromJson(data);
    final token = (data['token'] ?? '').toString();
    if (token.isEmpty) {
      throw ApiException(
        'Token tidak ditemukan pada respons login.',
        statusCode: res.statusCode,
      );
    }
    return (user, token);
  }

  /// GET /api/v1/auth/me
  Future<UserProfile> me() async {
    final res = await api.get(AppConfig.epAuthMe);
    return UserProfile.fromJson(_asMap(res.data));
  }

  Future<ApiResponse<dynamic>> _withPhotoIfAny(
    String path,
    Map<String, String> fields,
    String? fotoPath,
  ) {
    if (fotoPath == null || fotoPath.isEmpty) {
      return api.post(path, body: fields);
    }
    final f = File(fotoPath);
    if (!f.existsSync()) {
      return api.post(path, body: fields);
    }
    return api.sendMultipart(
      method: 'post',
      path: path,
      fields: fields,
      file: XFile(fotoPath),
    );
  }
}

Map<String, dynamic> _asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  throw ApiException('Struktur data dari server tidak sesuai kontrak.');
}
