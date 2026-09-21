import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import 'app_config.dart';
import 'exceptions.dart';
import 'session_controller.dart';

/// Lightweight parsed API response preserving the documented envelope.
class ApiResponse<T> {
  final int statusCode;
  final bool success;
  final String message;
  final T? data;

  const ApiResponse({
    required this.statusCode,
    required this.success,
    required this.message,
    this.data,
  });
}

/// Single centralised HTTP client for the whole app.
///
/// Responsibilities (UKK contract, section "KETENTUAN GLOBAL"):
///  - prefixes every path with [AppConfig.apiBaseUrl];
///  - sends `x-app-key` on every request EXCEPT the two public maker
///    register/login endpoints;
///  - sends `Authorization: Bearer <jwt>` whenever a token is stored;
///  - enforces a timeout;
///  - parses the standard success/error envelope;
///  - converts failures into typed, user-friendly [AppException]s.
class ApiClient {
  final http.Client _http;
  final SessionController session;

  ApiClient({http.Client? client, required this.session})
      : _http = client ?? http.Client();

  static const List<String> _publicMakerPaths = [
    AppConfig.epMakerRegister,
    AppConfig.epMakerLogin,
    AppConfig.epMakerCheckKey,
  ];

  Uri _uri(String path, Map<String, String>? query) {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    final cleanedPath =
        path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse(
      '${base.toString().replaceAll(RegExp(r'/+$'), '')}/$cleanedPath',
    ).replace(queryParameters: (query == null || query.isEmpty) ? null : query);
  }

  Future<Map<String, String>> _headers({
    required String path,
    bool jsonBody = true,
  }) async {
    final headers = <String, String>{};
    final isPublic = _publicMakerPaths.contains(path);
    if (!isPublic) {
      final appKey = await session.appKey;
      if (appKey != null && appKey.isNotEmpty) {
        headers['x-app-key'] = appKey;
      }
      final token = await session.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    if (jsonBody) headers['Content-Type'] = 'application/json';
    headers['Accept'] = 'application/json';
    return headers;
  }

  /// GET with envelope parsing.
  Future<ApiResponse<dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    try {
      final res = await _http
          .get(_uri(path, query), headers: await _headers(path: path))
          .timeout(AppConfig.apiTimeout);
      return _handle(res);
    } on SocketException {
      throw NetworkException(
          'Tidak ada koneksi internet. Periksa jaringan Anda lalu coba lagi.');
    } on http.ClientException {
      throw NetworkException(
          'Gagal terhubung ke server. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw TimeoutException(
          'Server tidak merespons dalam waktu yang ditentukan. Coba lagi.');
    }
  }

  /// POST with a JSON body.
  Future<ApiResponse<dynamic>> post(
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    try {
      final res = await _http
          .post(_uri(path, query),
              headers: await _headers(path: path),
              body: body == null ? null : jsonEncode(body))
          .timeout(AppConfig.apiTimeout);
      return _handle(res);
    } on SocketException {
      throw NetworkException(
          'Tidak ada koneksi internet. Periksa jaringan Anda lalu coba lagi.');
    } on http.ClientException {
      throw NetworkException(
          'Gagal terhubung ke server. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw TimeoutException(
          'Server tidak merespons dalam waktu yang ditentukan. Coba lagi.');
    }
  }

  /// PUT with a JSON body.
  Future<ApiResponse<dynamic>> put(
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    try {
      final res = await _http
          .put(_uri(path, query),
              headers: await _headers(path: path),
              body: body == null ? null : jsonEncode(body))
          .timeout(AppConfig.apiTimeout);
      return _handle(res);
    } on SocketException {
      throw NetworkException(
          'Tidak ada koneksi internet. Periksa jaringan Anda lalu coba lagi.');
    } on http.ClientException {
      throw NetworkException(
          'Gagal terhubung ke server. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw TimeoutException(
          'Server tidak merespons dalam waktu yang ditentukan. Coba lagi.');
    }
  }

  /// DELETE.
  Future<ApiResponse<dynamic>> delete(
    String path, {
    Map<String, String>? query,
  }) async {
    try {
      final res = await _http
          .delete(_uri(path, query), headers: await _headers(path: path))
          .timeout(AppConfig.apiTimeout);
      return _handle(res);
    } on SocketException {
      throw NetworkException(
          'Tidak ada koneksi internet. Periksa jaringan Anda lalu coba lagi.');
    } on http.ClientException {
      throw NetworkException(
          'Gagal terhubung ke server. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw TimeoutException(
          'Server tidak merespons dalam waktu yang ditentukan. Coba lagi.');
    }
  }

  /// Multipart POST/PUT for endpoints that accept an optional `foto` file.
  ///
  /// Text [fields] are always sent; the binary [file] is attached only when
  /// provided, so "no photo chosen" still produces a valid multipart request.
  Future<ApiResponse<dynamic>> sendMultipart({
    required String method, // 'post' or 'put'
    required String path,
    required Map<String, String> fields,
    XFile? file,
    String fileField = 'foto',
  }) async {
    try {
      final uri = _uri(path, null);
      final headers = await _headers(path: path, jsonBody: false);
      final request = http.MultipartRequest(method.toUpperCase(), uri)
        ..headers.addAll(headers)
        ..fields.addAll(fields);
      if (file != null) {
        final bytes = await file.readAsBytes();
        final mediaType = _mediaTypeFor(file);
        request.files.add(http.MultipartFile.fromBytes(
          fileField,
          bytes,
          filename: file.name.isNotEmpty ? file.name : 'upload.jpg',
          contentType: mediaType,
        ));
      }
      final streamed =
          await _http.send(request).timeout(AppConfig.apiTimeout);
      final res = await http.Response.fromStream(streamed)
          .timeout(AppConfig.apiTimeout);
      return _handle(res);
    } on SocketException {
      throw NetworkException(
          'Tidak ada koneksi internet. Periksa jaringan Anda lalu coba lagi.');
    } on http.ClientException {
      throw NetworkException(
          'Gagal terhubung ke server. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw TimeoutException(
          'Server tidak merespons dalam waktu yang ditentukan. Coba lagi.');
    }
  }

  MediaType? _mediaTypeFor(XFile file) {
    final name = file.name.toLowerCase();
    String? mime = lookupMimeType(name, headerBytes: null);
    mime ??= switch (name.split('.').last) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
    if (mime == null) return MediaType('application', 'octet-stream');
    final parts = mime.split('/');
    return MediaType(parts[0], parts[1]);
  }

  // ---- envelope handling ----

  ApiResponse<dynamic> _handle(http.Response res) {
    Map<String, dynamic>? json;
    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (_) {
        json = null;
      }
    }

    if (json == null) {
      throw FormatException(
          'Server mengembalikan format data yang tidak dikenal (HTTP ${res.statusCode}).');
    }

    final code = (json['statusCode'] as num?)?.toInt() ?? res.statusCode;
    final success = json['success'] == true;
    final message = (json['message'] ?? '').toString();
    final data = json['data'];

    if (code == 401 || (!success && code == 401)) {
      throw UnauthorizedException(
        message.isEmpty ? 'Sesi Anda berakhir. Silakan login kembali.' : message,
        statusCode: code,
      );
    }
    if (!success) {
      throw ApiException(
        message.isEmpty ? 'Terjadi kesalahan pada server (HTTP $code).' : message,
        statusCode: code,
      );
    }
    return ApiResponse<dynamic>(
      statusCode: code,
      success: true,
      message: message,
      data: data,
    );
  }
}

/// Minimal file abstraction so repositories don't import image_picker.
class XFile {
  final String path;
  final String name;
  XFile(this.path, {String? nameOverride}) : name = nameOverride ?? _base(path);

  static String _base(String p) {
    final norm = p.replaceAll('\\', '/');
    final i = norm.lastIndexOf('/');
    return i >= 0 ? norm.substring(i + 1) : norm;
  }

  Future<List<int>> readAsBytes() => File(path).readAsBytes();
}
