import 'package:flutter/material.dart';

import '../../core/exceptions.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../core/session_controller.dart';
import '../../data/models/models.dart';
import '../auth/auth_pages.dart';
import '../onboarding/onboarding_page.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  UserProfile? _profile;
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
      final user = await AuthScope.of(context).auth.me();
      if (!mounted) return;
      setState(() => _profile = user);
      await AuthScope.of(context).session.saveSession(
        SessionData(
          token: AuthScope.of(context).session.current!.token,
          role: user.role,
          username: user.username,
          nama: user.namaUnit,
          alamat: user.alamat,
          telp: user.telp,
          foto: user.foto,
          saldoPoin: user.saldoPoin,
        ),
      );
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StateContainer(
      loading: _loading,
      error: _error,
      isEmpty: false,
      onRetry: _load,
      child: _profile == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // 1. Profile Hero Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppTheme.darkCardGradient,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: .08)),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white.withValues(alpha: .2),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _profile!.namaUnit ?? 'Bank Sampah Unit',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ADMIN PENGELOLA UNIT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '@${_profile!.username}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Unit Details Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Unit Pengelola',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: AppTheme.line, height: 1),
                      const SizedBox(height: 14),
                      _itemTile(
                        Icons.apartment_rounded,
                        'Nama Unit',
                        _profile!.namaUnit ?? '-',
                      ),
                      _itemTile(
                        Icons.person_outline_rounded,
                        'Penanggung Jawab / Pengelola',
                        _profile!.namaPengelola ?? '-',
                      ),
                      _itemTile(
                        Icons.phone_outlined,
                        'Nomor Telepon',
                        _profile!.telp ?? '-',
                      ),
                      _itemTile(
                        Icons.location_on_outlined,
                        'Alamat Unit',
                        _profile!.alamat ?? 'Belum diatur',
                      ),
                      _itemTile(
                        Icons.badge_outlined,
                        'Username Akun',
                        '@${_profile!.username}',
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Operational Guide Action
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.greenLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: const Icon(
                      Icons.menu_book_rounded,
                      color: AppTheme.green,
                      size: 24,
                    ),
                    title: const Text(
                      'Buka Panduan Aplikasi',
                      style: TextStyle(
                        color: AppTheme.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Lihat kembali langkah operasional bank sampah',
                      style: TextStyle(color: AppTheme.subtle, fontSize: 12),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppTheme.green,
                      size: 14,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OnboardingPage(isModal: true),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // 4. Logout Action
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.redLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppTheme.red,
                      size: 24,
                    ),
                    title: const Text(
                      'Keluar dari Akun',
                      style: TextStyle(
                        color: AppTheme.red,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Akhiri sesi masuk admin di perangkat ini',
                      style: TextStyle(color: AppTheme.subtle, fontSize: 12),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppTheme.red,
                      size: 14,
                    ),
                    onTap: _confirmLogout,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _itemTile(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.all(22),
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
