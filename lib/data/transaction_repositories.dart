import 'package:sampahbank/core/exceptions.dart';

import '../core/api_client.dart';
import '../core/app_config.dart';
import 'models/models.dart';

class DepositRepository {
  final ApiClient api;
  DepositRepository(this.api);

  /// POST /api/v1/setor-sampah/pengajuan
  Future<SetorSampah> submit({
    required String tanggal,
    required String catatan,
    required List<({String kategoriSampahId, double beratKg})> items,
  }) async {
    final res = await api.post(
      AppConfig.epSetorPengajuan,
      body: {
        'tanggal': tanggal,
        'catatan': catatan,
        'items': [
          for (final item in items)
            {
              'kategoriSampahId': item.kategoriSampahId,
              'beratKg': item.beratKg,
            },
        ],
      },
    );
    return SetorSampah.fromJson(_map(res.data));
  }

  /// GET /api/v1/setor-sampah/my-setor?bulan=YYYY-MM
  Future<List<SetorSampah>> mine({String? bulan}) async {
    final res = await api.get(
      AppConfig.epSetorMySetor,
      query: bulan == null ? null : {'bulan': bulan},
    );
    return _list(res.data, SetorSampah.fromJson);
  }

  /// GET /api/v1/setor-sampah/admin/list?status=...&bulan=...
  Future<List<SetorSampah>> adminList({String? status, String? bulan}) async {
    final query = <String, String>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (bulan != null && bulan.isNotEmpty) query['bulan'] = bulan;
    final res = await api.get(
      AppConfig.epSetorAdminList,
      query: query.isEmpty ? null : query,
    );
    return _list(res.data, SetorSampah.fromJson);
  }

  /// GET /api/v1/setor-sampah/{id}
  Future<SetorSampah> detail(String id) async {
    final res = await api.get('${AppConfig.epSetorDetail}/$id');
    return SetorSampah.fromJson(_map(res.data));
  }

  /// PUT /api/v1/setor-sampah/admin/verify/{id}
  Future<SetorSampah> verify(
    String id, {
    required String status,
    required String catatanAdmin,
    List<({String kategoriSampahId, double beratKgReal})>? itemsReal,
  }) async {
    final res = await api.put(
      '${AppConfig.epSetorAdminVerify}/$id',
      body: {
        'status': status,
        'catatanAdmin': catatanAdmin,
        if (itemsReal != null)
          'itemsReal': [
            for (final item in itemsReal)
              {
                'kategoriSampahId': item.kategoriSampahId,
                'beratKgReal': item.beratKgReal,
              },
          ],
      },
    );
    return SetorSampah.fromJson(_map(res.data));
  }
}

class RedemptionRepository {
  final ApiClient api;
  RedemptionRepository(this.api);

  /// POST /api/v1/penukaran-poin/tukar
  Future<PenukaranPoin> exchange(String hadiahId) async {
    final res = await api.post(
      AppConfig.epPenukaranTukar,
      body: {'hadiahId': hadiahId},
    );
    return PenukaranPoin.fromJson(_map(res.data));
  }

  /// GET /api/v1/penukaran-poin/my-penukaran
  Future<List<PenukaranPoin>> mine() async {
    final res = await api.get(AppConfig.epPenukaranMy);
    return _list(res.data, PenukaranPoin.fromJson);
  }

  /// GET /api/v1/penukaran-poin/admin/list?bulan=YYYY-MM
  Future<List<PenukaranPoin>> adminList({String? bulan}) async {
    final res = await api.get(
      AppConfig.epPenukaranAdminList,
      query: bulan == null ? null : {'bulan': bulan},
    );
    return _list(res.data, PenukaranPoin.fromJson);
  }

  /// PUT /api/v1/penukaran-poin/admin/status/{id}
  Future<PenukaranPoin> updateStatus(String id, String status) async {
    final res = await api.put(
      '${AppConfig.epPenukaranAdminStatus}/$id',
      body: {'status': status},
    );
    return PenukaranPoin.fromJson(_map(res.data));
  }

  /// GET /api/v1/penukaran-poin/nota/{id}
  Future<PenukaranPoin> note(String id) async {
    final res = await api.get('${AppConfig.epPenukaranNota}/$id');
    return PenukaranPoin.fromJson(_map(res.data));
  }
}

class DashboardRepository {
  final ApiClient api;
  DashboardRepository(this.api);

  /// GET /api/v1/dashboard/summary (nasabah).
  Future<NasabahDashboard> nasabahSummary() async {
    final res = await api.get(AppConfig.epDashboardSummary);
    final summary = NasabahDashboard.fromJson(_map(res.data));
    List<SetorSampah> deposits = const [];
    List<PenukaranPoin> redemptions = const [];
    try {
      deposits = await DepositRepository(api).mine();
    } on AppException {
      deposits = const [];
    }
    try {
      redemptions = await RedemptionRepository(api).mine();
    } on AppException {
      redemptions = const [];
    }

    final completedDeposits = deposits
        .where((item) => item.status.toLowerCase() == 'selesai')
        .toList();
    final completedRedemptions = redemptions
        .where((item) => item.status.toLowerCase() == 'selesai')
        .toList();
    final totalKg = completedDeposits.fold<double>(
      0,
      (total, item) => total + item.totalBeratKg,
    );
    final earned = completedDeposits.fold<double>(
      0,
      (total, item) => total + item.totalPoin,
    );
    final spent = completedRedemptions.fold<double>(
      0,
      (total, item) => total + item.poinTerpakai,
    );
    return NasabahDashboard(
      saldoPoin: summary.saldoPoin == 0 ? earned - spent : summary.saldoPoin,
      totalSampahKg: summary.totalSampahKg == 0
          ? totalKg
          : summary.totalSampahKg,
      totalPoinDidapat: summary.totalPoinDidapat == 0
          ? earned
          : summary.totalPoinDidapat,
      totalPoinDitukar: summary.totalPoinDitukar == 0
          ? spent
          : summary.totalPoinDitukar,
      jumlahSetor: deposits.isEmpty ? summary.jumlahSetor : deposits.length,
      jumlahPenukaran: redemptions.isEmpty
          ? summary.jumlahPenukaran
          : redemptions.length,
      setorTerakhir: _latest(deposits) ?? summary.setorTerakhir,
      tukarTerakhir: _latest(redemptions) ?? summary.tukarTerakhir,
    );
  }

  T? _latest<T>(List<T> items) {
    if (items.isEmpty) return null;
    final sorted = [...items];
    sorted.sort((a, b) {
      final aDate =
          DateTime.tryParse(_dateOf(a)) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          DateTime.tryParse(_dateOf(b)) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate);
    });
    return sorted.last;
  }

  String _dateOf<T>(T item) => switch (item) {
    SetorSampah value => value.tanggal,
    PenukaranPoin value => value.tanggal,
    _ => '',
  };

  /// GET /api/v1/dashboard/stats (admin / app maker).
  Future<AdminDashboard> adminStats() async {
    final res = await api.get(AppConfig.epDashboardStats);
    return AdminDashboard.fromJson(_map(res.data));
  }
}

class RekapRepository {
  final ApiClient api;
  RekapRepository(this.api);

  /// GET /api/v1/rekapitulasi/bulanan?bulan=YYYY-MM (bulan is mandatory).
  Future<RekapBulanan> monthly(String bulan) async {
    final res = await api.get(
      AppConfig.epRekapBulanan,
      query: {'bulan': bulan},
    );
    return RekapBulanan.fromJson(_map(res.data));
  }
}

Map<String, dynamic> _map(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  throw ApiException('Struktur data dari server tidak sesuai kontrak.');
}

List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
  if (data is List) {
    return data.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
  throw ApiException('Data yang diterima bukan berupa daftar.');
}
