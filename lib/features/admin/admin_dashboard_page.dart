import 'package:flutter/material.dart';

import '../../core/exceptions.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/transaction_repositories.dart';
import '../auth/auth_pages.dart';
import '../onboarding/onboarding_page.dart';
import 'models/models.dart';

class AdminDashboardPage extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const AdminDashboardPage({super.key, this.onNavigate});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  AdminDashboard? _data;
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
      final data = await repo.adminStats();
      if (!mounted) return;
      setState(() => _data = data);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat statistik admin.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthScope.of(context).session.current;
    final unitName = session?.nama ?? 'Bank Sampah Unit';

    return RefreshIndicator(
      color: AppTheme.green,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // 1. Welcome Greeting Header
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.greenLight,
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppTheme.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unitName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Unit Pengelola Aktif',
                          style: TextStyle(
                            color: AppTheme.subtle,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.greenLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  Formatters.date(Formatters.isoNow()),
                  style: const TextStyle(
                    color: AppTheme.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          StateContainer(
            loading: _loading,
            error: _error,
            isEmpty: false,
            onRetry: _load,
            child: _data == null
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Hero Summary Banner
                      _buildHeroCard(_data!),

                      const SizedBox(height: 24),

                      // 3. Quick Action Shortcuts
                      const Text(
                        'Aksi Cepat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pintasan operasional harian bank sampah.',
                        style: TextStyle(color: AppTheme.subtle, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActions(),

                      const SizedBox(height: 24),

                      // 4. Data Master & Entities Grid
                      const Text(
                        'Ringkasan Data Unit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Status entitas yang terdaftar pada sistem.',
                        style: TextStyle(color: AppTheme.subtle, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      _buildStatCards(_data!),

                      const SizedBox(height: 22),

                      // 5. Guide banner
                      _buildGuideBanner(context),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(AdminDashboard data) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.greenGlow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/logo2.png',
                width: 140,
                height: 140,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Pencapaian Unit Sampah',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.scale_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Sampah Masuk',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .85),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${Formatters.kg(data.totalBeratSampahKg)} kg',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.savings_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Poin Diberikan',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .85),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              Formatters.poin(data.totalPoinTersalurkan),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Bersama nasabah menggerakkan ekonomi sirkular ramah lingkungan.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      (
        'Verifikasi Setor',
        'Validasi timbangan',
        Icons.fact_check_rounded,
        AppTheme.green,
        AppTheme.greenLight,
        4,
      ),
      (
        'Tukar Hadiah',
        'Klaim reward nasabah',
        Icons.redeem_rounded,
        AppTheme.amber,
        AppTheme.amberLight,
        5,
      ),
      (
        'Data Nasabah',
        'Kelola anggota unit',
        Icons.people_alt_rounded,
        AppTheme.blue,
        AppTheme.blueLight,
        1,
      ),
      (
        'Rekap Laporan',
        'Statistik & tonase',
        Icons.bar_chart_rounded,
        const Color(0xFF673AB7),
        const Color(0xFFEDE7F6),
        6,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.45,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) {
        final item = actions[i];
        return Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => widget.onNavigate?.call(item.$6),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.$5,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.$3, color: item.$4, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    item.$1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.$2,
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
          ),
        );
      },
    );
  }

  Widget _buildStatCards(AdminDashboard data) {
    final stats = [
      (
        'Total Nasabah',
        '${data.totalNasabah}',
        'Nasabah terdaftar',
        Icons.group_outlined,
        AppTheme.blue,
        AppTheme.blueLight,
        1,
      ),
      (
        'Kategori Sampah',
        '${data.totalKategoriSampah}',
        'Jenis sampah aktif',
        Icons.recycling_outlined,
        AppTheme.green,
        AppTheme.greenLight,
        2,
      ),
      (
        'Transaksi Setor',
        '${data.totalTransaksiSetor}',
        'Aktivitas setor',
        Icons.local_shipping_outlined,
        AppTheme.amber,
        AppTheme.amberLight,
        4,
      ),
      (
        'Katalog Hadiah',
        '${data.totalHadiah}',
        'Reward tersedia',
        Icons.card_giftcard_outlined,
        const Color(0xFF673AB7),
        const Color(0xFFEDE7F6),
        3,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemCount: stats.length,
      itemBuilder: (context, i) {
        final s = stats[i];
        return Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => widget.onNavigate?.call(s.$7),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: s.$6,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(s.$4, color: s.$5, size: 18),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppTheme.subtleLighter,
                        size: 13,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.subtle,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuideBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.greenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppTheme.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Panduan Pengelola',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pelajari standar operasional timbangan, verifikasi, dan penukaran poin.',
                  style: TextStyle(color: AppTheme.subtle, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Buka Panduan',
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OnboardingPage(isModal: true),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
