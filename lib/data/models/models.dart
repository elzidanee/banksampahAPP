/// Contract-faithful models for the UKK Bank Sampah API.
///
/// Parsing rules:
///  - UUIDs stay String;
///  - numeric fields parse int-or-double safely through [numOf];
///  - every nested object may be absent → nullable fields;
///  - unknown extra JSON keys are ignored.
library;

double? numOf(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? intOf(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String? strOf(dynamic v) => v?.toString();

// ---------------------------------------------------------------------------
// Auth / user
// ---------------------------------------------------------------------------

class UserProfile {
  final String id;
  final String username;
  final String role;
  final String? nama;
  final String? alamat;
  final String? telp;
  final double? saldoPoin;
  final String? foto;
  // Admin-only nested info.
  final String? namaUnit;
  final String? namaPengelola;

  const UserProfile({
    required this.id,
    required this.username,
    required this.role,
    this.nama,
    this.alamat,
    this.telp,
    this.saldoPoin,
    this.foto,
    this.namaUnit,
    this.namaPengelola,
  });

  bool get isNasabah => role == 'NASABAH';
  bool get isAdmin => role == 'ADMIN';

  factory UserProfile.fromJson(Map<String, dynamic> j) {
    final nasabah = j['nasabah'];
    final admin = j['adminBank'];
    return UserProfile(
      id: strOf(j['id']) ?? '',
      username: strOf(j['username']) ?? '',
      role: strOf(j['role']) ?? '',
      nama: nasabah is Map ? strOf(nasabah['namaNasabah']) : null,
      alamat: nasabah is Map ? strOf(nasabah['alamat']) : null,
      telp: nasabah is Map
          ? strOf(nasabah['telp'])
          : (admin is Map ? strOf(admin['telp']) : null),
      saldoPoin: nasabah is Map ? numOf(nasabah['saldoPoin']) : null,
      foto: nasabah is Map ? strOf(nasabah['foto']) : null,
      namaUnit: admin is Map ? strOf(admin['namaUnit']) : null,
      namaPengelola: admin is Map ? strOf(admin['namaPengelola']) : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Kategori sampah
// ---------------------------------------------------------------------------

class KategoriSampah {
  final String id;
  final String namaKategori;
  final double hargaPerKg;
  final double poinPerKg;
  final String jenis;
  final String? foto;

  const KategoriSampah({
    required this.id,
    required this.namaKategori,
    required this.hargaPerKg,
    required this.poinPerKg,
    required this.jenis,
    this.foto,
  });

  factory KategoriSampah.fromJson(Map<String, dynamic> j) => KategoriSampah(
    id: strOf(j['id']) ?? '',
    namaKategori: strOf(j['namaKategori']) ?? '-',
    hargaPerKg: numOf(j['hargaPerKg']) ?? 0,
    poinPerKg: numOf(j['poinPerKg']) ?? 0,
    jenis: strOf(j['jenis']) ?? '-',
    foto: strOf(j['foto']),
  );

  static const List<String> jenisOptions = [
    'plastik',
    'kertas',
    'logam',
    'kaca',
  ];
}

// ---------------------------------------------------------------------------
// Setor sampah
// ---------------------------------------------------------------------------

class SetorItem {
  final String kategoriSampahId;
  final String? namaKategori;
  final String? jenis;
  final double beratKg;
  final double poinPerKg;
  final double subtotalPoin;

  const SetorItem({
    required this.kategoriSampahId,
    this.namaKategori,
    this.jenis,
    required this.beratKg,
    this.poinPerKg = 0,
    this.subtotalPoin = 0,
  });

  /// my-setor nests name under `kategoriSampah`; detail returns flat `kategori`.
  factory SetorItem.fromJson(Map<String, dynamic> j) {
    final k = j['kategoriSampah'];
    return SetorItem(
      kategoriSampahId: strOf(j['kategoriSampahId']) ?? '',
      namaKategori:
          strOf(j['kategori']) ?? (k is Map ? strOf(k['namaKategori']) : null),
      jenis: k is Map ? strOf(k['jenis']) : strOf(j['jenis']),
      beratKg: numOf(j['beratKg']) ?? numOf(j['beratKgReal']) ?? 0,
      poinPerKg: numOf(j['poinPerKg']) ?? 0,
      subtotalPoin: numOf(j['subtotalPoin']) ?? 0,
    );
  }
}

class SetorSampah {
  final String id;
  final String kodeSetor;
  final String tanggal; // ISO-8601 verbatim
  final String status;
  final double totalBeratKg;
  final double totalPoin;
  final String? catatan;
  final String? catatanAdmin;
  final String? namaNasabah;
  final String? telpNasabah;
  final List<SetorItem> items;

  const SetorSampah({
    required this.id,
    required this.kodeSetor,
    required this.tanggal,
    required this.status,
    required this.totalBeratKg,
    required this.totalPoin,
    this.catatan,
    this.catatanAdmin,
    this.namaNasabah,
    this.telpNasabah,
    required this.items,
  });

  factory SetorSampah.fromJson(Map<String, dynamic> j) {
    final n = j['nasabah'];
    final details = j['detailSetors'];
    return SetorSampah(
      id: strOf(j['id']) ?? '',
      kodeSetor: strOf(j['kodeSetor']) ?? '-',
      tanggal: strOf(j['tanggal']) ?? '',
      status: strOf(j['status']) ?? '-',
      totalBeratKg: numOf(j['totalBeratKg']) ?? numOf(j['beratKg']) ?? 0,
      totalPoin:
          numOf(j['totalPoin']) ??
          numOf(j['estimasiTotalPoin']) ??
          numOf(j['poin']) ??
          0,
      catatan: strOf(j['catatan']),
      catatanAdmin: strOf(j['catatanAdmin']),
      namaNasabah: n is Map ? strOf(n['namaNasabah']) : null,
      telpNasabah: n is Map ? strOf(n['telp']) : null,
      items: details is List
          ? details
                .whereType<Map<String, dynamic>>()
                .map(SetorItem.fromJson)
                .toList()
          : const [],
    );
  }
}

// ---------------------------------------------------------------------------
// Hadiah & penukaran
// ---------------------------------------------------------------------------

class Hadiah {
  final String id;
  final String namaHadiah;
  final double poinDibutuhkan;
  final int stok;
  final String? foto;

  const Hadiah({
    required this.id,
    required this.namaHadiah,
    required this.poinDibutuhkan,
    required this.stok,
    this.foto,
  });

  factory Hadiah.fromJson(Map<String, dynamic> j) => Hadiah(
    id: strOf(j['id']) ?? '',
    namaHadiah: strOf(j['namaHadiah']) ?? '-',
    poinDibutuhkan: numOf(j['poinDibutuhkan']) ?? 0,
    stok: intOf(j['stok']) ?? 0,
    foto: strOf(j['foto']),
  );
}

class PenukaranPoin {
  final String id;
  final String kodePenukaran;
  final String tanggal;
  final String status;
  final double poinTerpakai;
  final double? sisaSaldoPoin;
  final String? namaHadiah;
  final String? fotoHadiah;
  final double? poinDibutuhkan;
  final String? namaNasabah;
  final String? telpNasabah;

  const PenukaranPoin({
    required this.id,
    required this.kodePenukaran,
    required this.tanggal,
    required this.status,
    required this.poinTerpakai,
    this.sisaSaldoPoin,
    this.namaHadiah,
    this.fotoHadiah,
    this.poinDibutuhkan,
    this.namaNasabah,
    this.telpNasabah,
  });

  factory PenukaranPoin.fromJson(Map<String, dynamic> j) {
    final h = j['hadiah'];
    final n = j['nasabah'];
    return PenukaranPoin(
      id: strOf(j['id']) ?? '',
      kodePenukaran: strOf(j['kodePenukaran']) ?? '-',
      tanggal: strOf(j['tanggal']) ?? '',
      status: strOf(j['status']) ?? '-',
      poinTerpakai: numOf(j['poinTerpakai']) ?? 0,
      sisaSaldoPoin: numOf(j['sisaSaldoPoin']),
      namaHadiah: h is Map ? strOf(h['namaHadiah']) : strOf(j['hadiah']),
      fotoHadiah: h is Map ? strOf(h['foto']) : null,
      poinDibutuhkan: h is Map ? numOf(h['poinDibutuhkan']) : null,
      namaNasabah: n is Map ? strOf(n['namaNasabah']) : null,
      telpNasabah: n is Map ? strOf(n['telp']) : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Admin nasabah CRUD
// ---------------------------------------------------------------------------

class NasabahAdmin {
  final String id;
  final String namaNasabah;
  final String? alamat;
  final String? telp;
  final String? tanggalLahir;
  final double saldoPoin;
  final String? foto;
  final String? username;

  const NasabahAdmin({
    required this.id,
    required this.namaNasabah,
    this.alamat,
    this.telp,
    this.tanggalLahir,
    required this.saldoPoin,
    this.foto,
    this.username,
  });

  factory NasabahAdmin.fromJson(Map<String, dynamic> j) {
    final u = j['user'];
    return NasabahAdmin(
      id: strOf(j['id']) ?? '',
      namaNasabah: strOf(j['namaNasabah']) ?? '-',
      alamat: strOf(j['alamat']),
      telp: strOf(j['telp']) ?? strOf(j['noTelepon']),
      tanggalLahir: strOf(j['tanggalLahir']) ?? strOf(j['tanggal_lahir']),
      saldoPoin: numOf(j['saldoPoin']) ?? 0,
      foto: strOf(j['foto']),
      username: u is Map ? strOf(u['username']) : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------

class NasabahDashboard {
  final double saldoPoin;
  final double totalSampahKg;
  final double totalPoinDidapat;
  final double totalPoinDitukar;
  final int jumlahSetor;
  final int jumlahPenukaran;
  final SetorSampah? setorTerakhir;
  final PenukaranPoin? tukarTerakhir;

  const NasabahDashboard({
    required this.saldoPoin,
    required this.totalSampahKg,
    required this.totalPoinDidapat,
    required this.totalPoinDitukar,
    this.jumlahSetor = 0,
    this.jumlahPenukaran = 0,
    this.setorTerakhir,
    this.tukarTerakhir,
  });

  factory NasabahDashboard.fromJson(Map<String, dynamic> j) {
    final payload = j['data'] is Map<String, dynamic>
        ? j['data'] as Map<String, dynamic>
        : j;
    final s = payload['transaksiTerakhirSetor'] ?? payload['setorTerakhir'];
    final t = payload['transaksiTerakhirTukar'] ?? payload['tukarTerakhir'];
    return NasabahDashboard(
      saldoPoin:
          numOf(payload['saldoPoinSaatIni']) ??
          numOf(payload['saldoPoin']) ??
          0,
      totalSampahKg:
          numOf(payload['totalSampahDisetorKg']) ??
          numOf(payload['totalSampahKg']) ??
          0,
      totalPoinDidapat: numOf(payload['totalPoinDidapat']) ?? 0,
      totalPoinDitukar: numOf(payload['totalPoinDitukar']) ?? 0,
      jumlahSetor:
          intOf(payload['totalPengajuanSetor']) ??
          intOf(payload['totalTransaksiSetor']) ??
          intOf(payload['jumlahSetor']) ??
          0,
      jumlahPenukaran:
          intOf(payload['totalPenukaranHadiah']) ??
          intOf(payload['totalTransaksiTukar']) ??
          intOf(payload['jumlahPenukaran']) ??
          0,
      setorTerakhir: s is Map<String, dynamic>
          ? SetorSampah.fromJson({
              ...s,
              'id': s['id'] ?? '',
              'totalBeratKg': s['totalBeratKg'] ?? s['beratKg'],
              'totalPoin': s['status'] == 'selesai'
                  ? (s['totalPoin'] ?? s['poin'])
                  : 0,
            })
          : null,
      tukarTerakhir: t is Map<String, dynamic>
          ? PenukaranPoin.fromJson({
              'id': '',
              'kodePenukaran': t['kodePenukaran'],
              'tanggal': t['tanggal'],
              'status': t['status'],
              'poinTerpakai': t['poin'],
              'hadiah': {'namaHadiah': t['hadiah']},
            })
          : null,
    );
  }
}

class AdminDashboard {
  final int totalNasabah;
  final int totalKategoriSampah;
  final int totalTransaksiSetor;
  final int totalHadiah;
  final double totalBeratSampahKg;
  final double totalPoinTersalurkan;

  const AdminDashboard({
    required this.totalNasabah,
    required this.totalKategoriSampah,
    required this.totalTransaksiSetor,
    required this.totalHadiah,
    required this.totalBeratSampahKg,
    required this.totalPoinTersalurkan,
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> j) => AdminDashboard(
    totalNasabah: intOf(j['totalNasabah']) ?? 0,
    totalKategoriSampah: intOf(j['totalKategoriSampah']) ?? 0,
    totalTransaksiSetor: intOf(j['totalTransaksiSetor']) ?? 0,
    totalHadiah: intOf(j['totalHadiah']) ?? 0,
    totalBeratSampahKg: numOf(j['totalBeratSampahKg']) ?? 0,
    totalPoinTersalurkan: numOf(j['totalPoinTersalurkan']) ?? 0,
  );
}

// ---------------------------------------------------------------------------
// Rekapitulasi bulanan
// ---------------------------------------------------------------------------

class RekapJenis {
  final double tonaseKg;
  final double rupiah;
  final double poin;
  const RekapJenis({
    required this.tonaseKg,
    required this.rupiah,
    required this.poin,
  });

  factory RekapJenis.fromJson(Map<String, dynamic> j) => RekapJenis(
    tonaseKg: numOf(j['tonaseKg']) ?? 0,
    rupiah: numOf(j['rupiah']) ?? 0,
    poin: numOf(j['poin']) ?? 0,
  );
}

class RekapBulanan {
  final String periode;
  final double totalKg;
  final double totalTon;
  final double totalEstimasiPembayaran;
  final double totalPoinDiterbitkan;
  final Map<String, RekapJenis> breakdownJenis;
  final int totalTransaksiPenukaran;
  final double totalPoinTerpakai;

  const RekapBulanan({
    required this.periode,
    required this.totalKg,
    required this.totalTon,
    required this.totalEstimasiPembayaran,
    required this.totalPoinDiterbitkan,
    required this.breakdownJenis,
    required this.totalTransaksiPenukaran,
    required this.totalPoinTerpakai,
  });

  factory RekapBulanan.fromJson(Map<String, dynamic> j) {
    final tonase = j['rekapitulasiTonase'];
    final t = tonase is Map<String, dynamic> ? tonase : <String, dynamic>{};
    final breakdown = j['breakdownJenisSampah'];
    final penukaran = j['rekapitulasiPenukaranPoin'];
    final p = penukaran is Map<String, dynamic>
        ? penukaran
        : <String, dynamic>{};
    return RekapBulanan(
      periode: strOf(j['periode']) ?? '-',
      totalKg: numOf(t['totalKg']) ?? 0,
      totalTon: numOf(t['totalTon']) ?? 0,
      totalEstimasiPembayaran: numOf(t['totalEstimasiPembayaranRupiah']) ?? 0,
      totalPoinDiterbitkan: numOf(t['totalPoinDiterbitkan']) ?? 0,
      breakdownJenis: breakdown is Map<String, dynamic>
          ? breakdown.map(
              (k, v) => MapEntry(
                k,
                v is Map<String, dynamic>
                    ? RekapJenis.fromJson(v)
                    : const RekapJenis(tonaseKg: 0, rupiah: 0, poin: 0),
              ),
            )
          : {},
      totalTransaksiPenukaran: intOf(p['totalTransaksiPenukaran']) ?? 0,
      totalPoinTerpakai: numOf(p['totalPoinTerpakai']) ?? 0,
    );
  }
}
