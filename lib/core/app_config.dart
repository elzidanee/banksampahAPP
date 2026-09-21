/// Global application configuration for the UKK Bank Sampah app.

class AppConfig {
  AppConfig._();

  // ---- API Configuration ----

  static const String apiBaseUrl =
      'https://learn.smktelkom-mlg.sch.id/bank_sampah/api/v1';

  static const String appKey = '60e64c80-4314-4ccf-9820-ab74f8c99da4';

  // ---- Endpoint paths ----

  static const String epMakerRegister = '/maker/register';
  static const String epMakerLogin = '/maker/login';
  static const String epMakerProfile = '/maker/profile';
  static const String epMakerCheckKey = '/maker/check-key';

  static const String epAuthNasabahRegister = '/auth/nasabah/register';
  static const String epAuthAdminRegister = '/auth/admin/register';
  static const String epAuthLogin = '/auth/login';
  static const String epAuthMe = '/auth/me';

  static const String epAdminNasabah = '/admin/nasabah';

  static const String epKategoriSampah = '/kategori-sampah';

  static const String epSetorPengajuan = '/setor-sampah/pengajuan';
  static const String epSetorDetail = '/setor-sampah';
  static const String epSetorMySetor = '/setor-sampah/my-setor';
  static const String epSetorAdminList = '/setor-sampah/admin/list';
  static const String epSetorAdminVerify = '/setor-sampah/admin/verify';

  static const String epHadiah = '/hadiah';

  static const String epPenukaranTukar = '/penukaran-poin/tukar';
  static const String epPenukaranMy = '/penukaran-poin/my-penukaran';
  static const String epPenukaranAdminList = '/penukaran-poin/admin/list';
  static const String epPenukaranAdminStatus = '/penukaran-poin/admin/status';
  static const String epPenukaranNota = '/penukaran-poin/nota';

  static const String epRekapBulanan = '/rekapitulasi/bulanan';

  static const String epDashboardSummary = '/dashboard/summary';
  static const String epDashboardStats = '/dashboard/stats';

  static const String epSeed = '/seed';

  // ---- Network Configuration ----

  static const Duration apiTimeout = Duration(seconds: 30);
}
