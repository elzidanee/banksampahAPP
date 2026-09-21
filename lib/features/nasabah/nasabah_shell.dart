import 'package:flutter/material.dart';
import 'package:sampahbank/data/models/models.dart';
import 'package:sampahbank/features/nasabah/history_page.dart';
import 'package:sampahbank/features/nasabah/redeem_page.dart';

import '../../core/exceptions.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/transaction_repositories.dart';
import '../auth/auth_pages.dart';
import '../onboarding/onboarding_page.dart';
import 'deposit_page.dart';
import 'catalog_page.dart';

class NasabahShell extends StatefulWidget {
  const NasabahShell({super.key});
  @override
  State<NasabahShell> createState() => _NasabahShellState();
}

class _NasabahShellState extends State<NasabahShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const NasabahDashboardPage(),
      const DepositPage(),
      const HistoryPage(),
      const RedeemPage(),
      const AccountPage(),
    ];
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Dock Background Card
              Container(
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.line),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _navItem(icon: Icons.home_rounded, label: 'Beranda', targetIndex: 0),
                    _navItem(icon: Icons.receipt_long_rounded, label: 'Riwayat', targetIndex: 2),
                    const SizedBox(width: 58), // Space for center floating Setor button
                    _navItem(icon: Icons.card_giftcard_rounded, label: 'Hadiah', targetIndex: 3),
                    _navItem(icon: Icons.person_rounded, label: 'Akun', targetIndex: 4),
                  ],
                ),
              ),

              // Center Floating Action Button: Setor Sampah
              Positioned(
                top: 0,
                child: GestureDetector(
                  onTap: () => setState(() => _index = 1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.green.withValues(alpha: _index == 1 ? 0.45 : 0.28),
                              blurRadius: _index == 1 ? 16 : 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white,
                            width: _index == 1 ? 3 : 2.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.recycling_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Setor',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: _index == 1 ? FontWeight.w800 : FontWeight.w600,
                          color: _index == 1 ? AppTheme.green : AppTheme.subtle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int targetIndex,
  }) {
    final active = _index == targetIndex;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = targetIndex),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: active ? AppTheme.greenLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: active ? AppTheme.green : AppTheme.subtle,
                  size: 21,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppTheme.green : AppTheme.subtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------
class NasabahDashboardPage extends StatefulWidget {
  const NasabahDashboardPage({super.key});
  @override
  State<NasabahDashboardPage> createState() => _NasabahDashboardPageState();
}

class _NasabahDashboardPageState extends State<NasabahDashboardPage>
    with SingleTickerProviderStateMixin {
  NasabahDashboard? _data;
  bool _loading = true;
  String? _error;

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(retryOnFailure: true));
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  Future<void> _load({bool retryOnFailure = false}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = DashboardRepository(AuthScope.of(context).api);
      final data = await repo.nasabahSummary();
      if (!mounted) return;
      setState(() => _data = data);
      final saldo = _data?.saldoPoin;
      if (saldo != null) await AuthScope.of(context).session.updateSaldo(saldo);
      _animCtrl.forward(from: 0);
    } on AppException catch (e) {
      if (retryOnFailure && mounted) await _load();
      else if (mounted) {
        setState(() => _error = e.message);
        await _showError(e.message, e.statusCode);
      }
    } catch (_) {
      if (retryOnFailure && mounted) await _load();
      else if (mounted) {
        const msg = 'Gagal memuat data dashboard.';
        setState(() => _error = msg);
        await _showError(msg, null);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showError(String message, int? statusCode) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dashboard tidak dapat dimuat'),
        content: Text(statusCode == null ? message : '\n\nStatus: '),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); _load(); }, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).session.current;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppTheme.green,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${user?.nama?.split(' ').first ?? 'Nasabah'}',
                            style: const TextStyle(color: AppTheme.ink, fontSize: 19, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          const Text('Ayo pilah & setor sampah hari ini!',
                            style: TextStyle(color: AppTheme.subtle, fontSize: 13)),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.greenLight,
                      backgroundImage: resolveImageUrl(user?.foto) != null
                          ? NetworkImage(resolveImageUrl(user!.foto)!) : null,
                      child: resolveImageUrl(user?.foto) == null
                          ? const Icon(Icons.person_rounded, color: AppTheme.green, size: 22) : null,
                    ),
                  ],
                ),
              ),
              StateContainer(
                loading: _loading, error: _error, onRetry: _load, isEmpty: false,
                child: _data == null ? const SizedBox.shrink() : FadeTransition(
                  opacity: _fade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BalanceCard(poin: _data!.saldoPoin),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _StatCard(
                            label: 'Total Setor',
                            value: '${_data!.totalSampahKg.toStringAsFixed(1)} kg',
                            type: _StatType.setor,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'Poin Didapat',
                            value: Formatters.poin(_data!.totalPoinDidapat),
                            type: _StatType.poin,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'Penukaran',
                            value: '${_data!.jumlahPenukaran}x',
                            type: _StatType.tukar,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _QuickBanner(
                        icon: Icons.recycling_outlined, label: 'Lihat Katalog Sampah',
                        subtitle: 'Cek jenis & nilai sampah',
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const KategoriSampahPage())),
                      ),
                      const SizedBox(height: 20),
                      const Text('Transaksi Terakhir',
                        style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 12),
                      _buildDepositCard(),
                      _buildRedeemCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepositCard() {
    final d = _data!.setorTerakhir;
    if (d == null) return _txCard(title: 'Setoran Terakhir', icon: Icons.recycling_rounded,
      gradient: AppTheme.primaryGradient,
      rows: const [('Kode','-'),('Tanggal','-'),('Berat','-'),('Poin','-')],
      status: ('Belum ada data', AppTheme.subtle),
      viewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())));
    final points = d.status == 'selesai' ? '${Formatters.poin(d.totalPoin)} Poin' : 'Belum diperoleh';
    return _txCard(title: 'Setoran Terakhir', icon: Icons.recycling_rounded,
      gradient: AppTheme.primaryGradient,
      rows: [('Kode', d.kodeSetor),('Tanggal', Formatters.date(d.tanggal)),
        ('Berat', '${d.totalBeratKg.toStringAsFixed(1)} kg'),('Poin', points)],
      status: StatusStyle.setor(d.status),
      viewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())));
  }

  Widget _buildRedeemCard() {
    final r = _data!.tukarTerakhir;
    if (r == null) return _txCard(title: 'Penukaran Terakhir', icon: Icons.swap_horiz_rounded,
      gradient: AppTheme.blueGradient,
      rows: const [('Kode','-'),('Tanggal','-'),('Hadiah','-'),('Poin Terpakai','-')],
      status: ('Belum ada data', AppTheme.subtle),
      viewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RedeemPage(initialTab: 1))));
    return _txCard(title: 'Penukaran Terakhir', icon: Icons.swap_horiz_rounded,
      gradient: AppTheme.blueGradient,
      rows: [('Kode', r.kodePenukaran),('Tanggal', Formatters.date(r.tanggal)),
        ('Hadiah', r.namaHadiah ?? '-'),('Poin Terpakai', '${Formatters.poin(r.poinTerpakai)} Poin')],
      status: StatusStyle.penukaran(r.status),
      viewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RedeemPage(initialTab: 1))));
  }

  Widget _txCard({
    required String title, required IconData icon, required LinearGradient gradient,
    required List<(String, String)> rows, required (String, Color) status, required VoidCallback viewAll,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.line), boxShadow: AppTheme.cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 17)),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.ink))),
          TextButton(onPressed: viewAll,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('Lihat Semua', style: TextStyle(fontSize: 12))),
        ]),
        const SizedBox(height: 12),
        for (final row in rows) Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            SizedBox(width: 110, child: Text(row.$1, style: const TextStyle(color: AppTheme.subtle, fontSize: 13))),
            Expanded(child: Text(row.$2, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.ink))),
          ]),
        ),
        const SizedBox(height: 4),
        Row(children: [
          const Expanded(child: Text('Status', style: TextStyle(color: AppTheme.subtle, fontSize: 13))),
          StatusChip(label: status.$1, color: status.$2),
        ]),
      ],
    ),
  );
}

// Balance card
class _BalanceCard extends StatelessWidget {
  final num? poin;
  const _BalanceCard({required this.poin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.greenGlow,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -12,
            right: -12,
            child: Opacity(
              opacity: 0.16,
              child: Image.asset(
                'assets/logo2.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.stars_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Total Poin', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              Text(Formatters.poin(poin),
                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, height: 1)),
              const SizedBox(height: 4),
              Text('poin terkumpul',
                style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

enum _StatType { setor, poin, tukar }

// Stat card with clean professional icon badges
class _StatCard extends StatelessWidget {
  final String label, value;
  final _StatType type;
  const _StatCard({required this.label, required this.value, required this.type});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.line),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: switch (type) {
                  _StatType.setor => AppTheme.greenLight,
                  _StatType.poin => AppTheme.amberLight,
                  _StatType.tukar => AppTheme.blueLight,
                },
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                switch (type) {
                  _StatType.setor => Icons.recycling_rounded,
                  _StatType.poin => Icons.monetization_on_rounded,
                  _StatType.tukar => Icons.redeem_rounded,
                },
                size: 18,
                color: switch (type) {
                  _StatType.setor => AppTheme.green,
                  _StatType.poin => AppTheme.amber,
                  _StatType.tukar => AppTheme.blue,
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppTheme.subtle, fontSize: 10, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Quick action banner
class _QuickBanner extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback? onTap;
  const _QuickBanner({required this.icon, required this.label, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.greenLight, borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.green.withValues(alpha: .3))),
          child: Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 19)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
              Text(subtitle, style: const TextStyle(color: AppTheme.subtle, fontSize: 12)),
            ])),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppTheme.green),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account Page
// ---------------------------------------------------------------------------
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).session.current;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(22),
                boxShadow: AppTheme.greenGlow,
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  child: CircleAvatar(
                    radius: 30, backgroundColor: AppTheme.greenLight,
                    backgroundImage: resolveImageUrl(user?.foto) != null
                        ? NetworkImage(resolveImageUrl(user!.foto)!) : null,
                    child: resolveImageUrl(user?.foto) == null
                        ? const Icon(Icons.person_rounded, color: AppTheme.green, size: 26) : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.nama ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('@${user?.username ?? '-'}',
                      style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(6)),
                      child: Text(user?.role ?? '-',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 16),
            // Info card
            Container(
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.line), boxShadow: AppTheme.cardShadow),
              child: Column(children: [
                _infoTile(Icons.location_on_rounded, 'Alamat', user?.alamat ?? '-'),
                Divider(color: AppTheme.line, height: 1, indent: 56),
                _infoTile(Icons.phone_rounded, 'Telepon', user?.telp ?? '-'),
                Divider(color: AppTheme.line, height: 1, indent: 56),
                _infoTile(Icons.stars_rounded, 'Saldo Poin',
                  user?.saldoPoin != null ? '${Formatters.poin(user?.saldoPoin)} poin' : '-',
                  valueColor: AppTheme.green),
              ]),
            ),
            const SizedBox(height: 14),
            // Panduan Aplikasi
            Container(
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.line), boxShadow: AppTheme.cardShadow),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Container(width: 34, height: 34,
                  decoration: BoxDecoration(color: AppTheme.greenLight, borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.menu_book_rounded, color: AppTheme.green, size: 18)),
                title: const Text('Panduan Aplikasi', style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: const Text('Lihat kembali alur & pengenalan aplikasi', style: TextStyle(color: AppTheme.subtle, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.subtle),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingPage(isModal: true)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Logout
            Container(
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.line), boxShadow: AppTheme.cardShadow),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Container(width: 34, height: 34,
                  decoration: BoxDecoration(color: AppTheme.redLight, borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.logout_rounded, color: AppTheme.red, size: 17)),
                title: const Text('Keluar', style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w600, fontSize: 15)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.subtle),
                onTap: () => _confirmLogout(context),
              ),
            ),
            const SizedBox(height: 24),
            const Center(child: Text('Bank Sampah Peduli v1.0.0',
              style: TextStyle(color: AppTheme.subtleLighter, fontSize: 11))),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Container(width: 34, height: 34,
          decoration: BoxDecoration(color: AppTheme.greenLight, borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: AppTheme.green, size: 17)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.subtle, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: valueColor ?? AppTheme.ink,
              fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        )),
      ]),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await AuthScope.of(context).session.clearSession();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }
}
