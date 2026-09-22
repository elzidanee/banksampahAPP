import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../auth/auth_pages.dart';
import '../onboarding/onboarding_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_hadiah_page.dart';
import 'admin_kategori_page.dart';
import 'admin_nasabah_page.dart';
import 'admin_penukaran_page.dart';
import 'admin_profile_page.dart';
import 'admin_rekap_page.dart';
import 'admin_setor_page.dart';

/// Admin navigation shell (drawer + indexed pages per UKK wireframe).
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _titles = [
    'Dashboard',
    'Data Nasabah',
    'Kategori Sampah',
    'Katalog Hadiah',
    'Verifikasi Setor',
    'Penukaran Poin',
    'Rekapitulasi',
    'Profil Unit',
  ];

  static const _icons = [
    Icons.dashboard_rounded,
    Icons.people_alt_rounded,
    Icons.recycling_rounded,
    Icons.card_giftcard_rounded,
    Icons.fact_check_rounded,
    Icons.swap_horizontal_circle_rounded,
    Icons.bar_chart_rounded,
    Icons.storefront_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final session = AuthScope.of(context).session.current;
    final unitName = session?.nama ?? 'Admin Bank Sampah';
    final username = session?.username ?? '-';

    final pages = [
      AdminDashboardPage(onNavigate: (i) => setState(() => _index = i)),
      const AdminNasabahPage(),
      const AdminKategoriPage(),
      const AdminHadiahPage(),
      const AdminSetorPage(),
      const AdminPenukaranPage(),
      const AdminRekapPage(),
      const AdminProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          if (_index != 7)
            IconButton(
              tooltip: 'Profil Unit',
              icon: const Icon(Icons.storefront_outlined),
              onPressed: () => setState(() => _index = 7),
            ),
          IconButton(
            tooltip: 'Panduan Aplikasi',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OnboardingPage(isModal: true),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.surface,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drawer Header
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppTheme.darkCardGradient,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: .08)),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withValues(alpha: .2),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PENGELOLA UNIT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                unitName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.alternate_email_rounded,
                            color: Colors.white70,
                            size: 13,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation Links
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    for (var i = 0; i < _titles.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _index == i
                                ? AppTheme.greenLight
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 2,
                            ),
                            leading: Icon(
                              _icons[i],
                              color: _index == i
                                  ? AppTheme.green
                                  : AppTheme.subtle,
                              size: 22,
                            ),
                            title: Text(
                              _titles[i],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _index == i
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _index == i
                                    ? AppTheme.green
                                    : AppTheme.inkMedium,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              setState(() => _index = i);
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: AppTheme.line, height: 1),
              ),

              // Guide Button
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.greenLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    leading: const Icon(
                      Icons.menu_book_rounded,
                      color: AppTheme.green,
                      size: 22,
                    ),
                    title: const Text(
                      'Panduan Aplikasi',
                      style: TextStyle(
                        color: AppTheme.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OnboardingPage(isModal: true),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Logout Button
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.redLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppTheme.red,
                      size: 22,
                    ),
                    title: const Text(
                      'Keluar',
                      style: TextStyle(
                        color: AppTheme.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    onTap: _confirmLogout,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: pages),
    );
  }

  Future<void> _confirmLogout() async {
    Navigator.pop(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.line),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.redLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppTheme.red,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Konfirmasi Keluar',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Anda yakin ingin keluar dari sesi pengelola bank sampah?',
                style: TextStyle(
                  color: AppTheme.subtle,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ya, Keluar'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.inkMedium,
                  side: const BorderSide(color: AppTheme.line),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    await AuthScope.of(context).session.clearSession();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
}
