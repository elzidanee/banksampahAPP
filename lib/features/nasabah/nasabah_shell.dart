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
      NasabahDashboardPage(onNavigate: (i) => setState(() => _index = i)),
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
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _navItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Beranda',
                targetIndex: 0,
              ),
              _navItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Riwayat',
                targetIndex: 2,
              ),
              _centerSetorButton(),
              _navItem(
                icon: Icons.card_giftcard_outlined,
                activeIcon: Icons.card_giftcard_rounded,
                label: 'Hadiah',
                targetIndex: 3,
              ),
              _navItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Akun',
                targetIndex: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _centerSetorButton() {
    final active = _index == 1;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = 1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: active ? AppTheme.greenDark : AppTheme.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Setor',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? AppTheme.green : AppTheme.subtle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int targetIndex,
  }) {
    final active = _index == targetIndex;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = targetIndex),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active ? AppTheme.green : AppTheme.subtle,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppTheme.green : AppTheme.subtle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Clean, Modern Dashboard for Nasabah
// ---------------------------------------------------------------------------

class NasabahDashboardPage extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const NasabahDashboardPage({super.key, this.onNavigate});

  @override
  State<NasabahDashboardPage> createState() => _NasabahDashboardPageState();
}

class _NasabahDashboardPageState extends State<NasabahDashboardPage> {
  NasabahDashboard? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = DashboardRepository(AuthScope.of(context).api);
      final data = await repo.nasabahSummary();
      if (!mounted) return;
      setState(() => _data = data);
      final saldo = _data?.saldoPoin;
      if (saldo != null) {
        await AuthScope.of(context).session.updateSaldo(saldo);
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat data dashboard.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).session.current;
    final firstName = user?.nama?.split(' ').first ?? 'Nasabah';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppTheme.green,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // Top Header Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.greenLight,
                    backgroundImage: resolveImageUrl(user?.foto) != null
                        ? NetworkImage(resolveImageUrl(user!.foto)!)
                        : null,
                    child: resolveImageUrl(user?.foto) == null
                        ? const Icon(
                            Icons.person_rounded,
                            color: AppTheme.green,
                            size: 20,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, $firstName',
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'Kelola tabungan sampah digitalmu',
                          style: TextStyle(
                            color: AppTheme.subtle,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Panduan Aplikasi',
                    icon: const Icon(
                      Icons.help_outline_rounded,
                      color: AppTheme.subtle,
                      size: 22,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OnboardingPage(isModal: true),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              StateContainer(
                loading: _loading,
                error: _error,
                onRetry: _load,
                isEmpty: false,
                child: _data == null
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Digital Wallet Card
                          _buildWalletCard(_data!.saldoPoin),

                          const SizedBox(height: 16),

                          // 2. Metrics summary row
                          Row(
                            children: [
                              _metricItem(
                                'Total Setor',
                                '${_data!.totalSampahKg.toStringAsFixed(1)} kg',
                                Icons.scale_outlined,
                                AppTheme.green,
                                AppTheme.greenLight,
                              ),
                              const SizedBox(width: 10),
                              _metricItem(
                                'Poin Masuk',
                                Formatters.poin(_data!.totalPoinDidapat),
                                Icons.savings_outlined,
                                AppTheme.amber,
                                AppTheme.amberLight,
                              ),
                              const SizedBox(width: 10),
                              _metricItem(
                                'Penukaran',
                                '${_data!.jumlahPenukaran}x',
                                Icons.redeem_outlined,
                                AppTheme.blue,
                                AppTheme.blueLight,
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // 3. Quick Action Grid
                          _buildQuickActionGrid(),

                          const SizedBox(height: 22),

                          // 4. Recent Transactions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Aktivitas Terakhir',
                                style: TextStyle(
                                  color: AppTheme.ink,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              TextButton(
                                onPressed: () => widget.onNavigate?.call(2),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Lihat Semua',
                                  style: TextStyle(fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildRecentDepositCard(),
                          _buildRecentRedeemCard(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(num? poin) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.darkCardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SALDO POIN AKTIF',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 12,
                      color: AppTheme.greenAccent,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Terverifikasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Formatters.poin(poin),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dapat ditukarkan dengan sembako & reward',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .65),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => widget.onNavigate?.call(1),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Setor Sampah',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: .25),
                      width: 1,
                    ),
                    minimumSize: const Size.fromHeight(42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => widget.onNavigate?.call(3),
                  icon: const Icon(Icons.card_giftcard_outlined, size: 17),
                  label: const Text(
                    'Tukar Hadiah',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricItem(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.subtle,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionGrid() {
    final actions = [
      (
        'Setor Sampah',
        Icons.recycling_rounded,
        AppTheme.green,
        () => widget.onNavigate?.call(1),
      ),
      (
        'Katalog Sampah',
        Icons.inventory_2_outlined,
        AppTheme.blue,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KategoriSampahPage()),
        ),
      ),
      (
        'Tukar Reward',
        Icons.card_giftcard_rounded,
        AppTheme.amber,
        () => widget.onNavigate?.call(3),
      ),
      (
        'Panduan',
        Icons.menu_book_rounded,
        const Color(0xFF673AB7),
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const OnboardingPage(isModal: true),
          ),
        ),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((item) {
          return InkWell(
            onTap: item.$4,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.$3.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.$2, color: item.$3, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.$1,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentDepositCard() {
    final d = _data!.setorTerakhir;
    if (d == null) {
      return _emptyActivityTile('Belum ada setoran sampah');
    }
    final status = StatusStyle.setor(d.status);
    final points = d.status == 'selesai'
        ? '+${Formatters.poin(d.totalPoin)} Poin'
        : 'Menunggu validasi';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.greenLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.recycling_rounded,
                  color: AppTheme.green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  d.kodeSetor,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              StatusChip(label: status.$1, color: status.$2),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${Formatters.date(d.tanggal)} • ${Formatters.kg(d.totalBeratKg)} kg',
                style: const TextStyle(color: AppTheme.subtle, fontSize: 12),
              ),
              Text(
                points,
                style: const TextStyle(
                  color: AppTheme.green,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRedeemCard() {
    final r = _data!.tukarTerakhir;
    if (r == null) {
      return _emptyActivityTile('Belum ada penukaran hadiah');
    }
    final status = StatusStyle.penukaran(r.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.blueLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.redeem_rounded,
                  color: AppTheme.blue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.namaHadiah ?? r.kodePenukaran,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              StatusChip(label: status.$1, color: status.$2),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.date(r.tanggal),
                style: const TextStyle(color: AppTheme.subtle, fontSize: 12),
              ),
              Text(
                '-${Formatters.poin(r.poinTerpakai)} Poin',
                style: const TextStyle(
                  color: AppTheme.red,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyActivityTile(String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.subtleLighter, size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppTheme.subtle, fontSize: 12.5)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Clean Account Page
// ---------------------------------------------------------------------------

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).session.current;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.line),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.greenLight,
                    backgroundImage: resolveImageUrl(user?.foto) != null
                        ? NetworkImage(resolveImageUrl(user!.foto)!)
                        : null,
                    child: resolveImageUrl(user?.foto) == null
                        ? const Icon(
                            Icons.person_rounded,
                            color: AppTheme.green,
                            size: 28,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nama ?? 'Nasabah',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${user?.username ?? '-'}',
                          style: const TextStyle(
                            color: AppTheme.subtle,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.greenLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NASABAH AKTIF',
                            style: TextStyle(
                              color: AppTheme.green,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Profile info details
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.line),
              ),
              child: Column(
                children: [
                  _infoItem(
                    Icons.location_on_outlined,
                    'Alamat',
                    user?.alamat ?? 'Belum diatur',
                  ),
                  const Divider(color: AppTheme.line, height: 1, indent: 50),
                  _infoItem(
                    Icons.phone_outlined,
                    'Nomor Telepon',
                    user?.telp ?? '-',
                  ),
                  const Divider(color: AppTheme.line, height: 1, indent: 50),
                  _infoItem(
                    Icons.savings_outlined,
                    'Total Poin',
                    user?.saldoPoin != null
                        ? '${Formatters.poin(user?.saldoPoin)} Poin'
                        : '0 Poin',
                    isHighlight: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Menu actions
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.line),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.menu_book_rounded,
                      color: AppTheme.green,
                      size: 20,
                    ),
                    title: const Text(
                      'Panduan Penggunaan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.subtle,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OnboardingPage(isModal: true),
                      ),
                    ),
                  ),
                  const Divider(color: AppTheme.line, height: 1, indent: 50),
                  ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppTheme.red,
                      size: 20,
                    ),
                    title: const Text(
                      'Keluar dari Akun',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.red,
                      ),
                    ),
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(
    IconData icon,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, color: isHighlight ? AppTheme.green : AppTheme.subtle, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.subtle, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: isHighlight ? AppTheme.green : AppTheme.ink,
                    fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Keluar dari Akun',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: const Text(
          'Anda yakin ingin mengakhiri sesi masuk pada perangkat ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await AuthScope.of(context).session.clearSession();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
}
