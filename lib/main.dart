import 'dart:async' as async;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:toastification/toastification.dart';

import 'core/api_client.dart';
import 'core/session_controller.dart';
import 'core/theme.dart';
import 'data/auth_repository.dart';
import 'features/auth/auth_pages.dart';
import 'features/onboarding/onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SampahBankApp());
}

class SampahBankApp extends StatefulWidget {
  const SampahBankApp({super.key});
  @override
  State<SampahBankApp> createState() => _SampahBankAppState();
}

class _SampahBankAppState extends State<SampahBankApp> {
  final SessionController _session = SessionController();
  late final ApiClient _api = ApiClient(session: _session);
  late final AuthRepository _auth = AuthRepository(_api);

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      session: _session,
      api: _api,
      auth: _auth,
      child: ToastificationWrapper(
        child: MaterialApp(
          title: 'Bank Sampah',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme(),
          home: const SplashPage(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Clean, Professional Splash Screen (No AI Slop / No Particle Canvas)
// ---------------------------------------------------------------------------

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _minDuration = Duration(milliseconds: 1200);

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  late DateTime _startedAt;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final scope = AuthScope.of(context);
    try {
      final seen = await hasSeenOnboarding();
      if (!mounted) return;
      if (!seen) {
        await _waitForMinimum();
        if (!mounted) return;
        _goToOnboarding();
        return;
      }

      final savedSession = await scope.session.load();
      if (!mounted) return;
      if (savedSession == null) {
        await _waitForMinimum();
        if (!mounted) return;
        _goToLogin();
        return;
      }
      final user = await scope.auth.me().timeout(const Duration(seconds: 15));
      if (!mounted) return;
      await _waitForMinimum();
      if (!mounted) return;
      _goToHome(user);
    } on async.TimeoutException {
      if (!mounted) return;
      await _waitForMinimum();
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Server tidak merespons. Periksa koneksi internet Anda.';
      });
    } catch (_) {
      if (!mounted) return;
      await scope.session.clearSession();
      if (!mounted) return;
      await _waitForMinimum();
      if (!mounted) return;
      _goToLogin();
    }
  }

  Future<void> _waitForMinimum() async {
    final elapsed = DateTime.now().difference(_startedAt);
    final remaining = _minDuration - elapsed;
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
  }

  void _goToOnboarding() => _push(const OnboardingPage());
  void _goToLogin() => _push(const LoginPage());
  void _goToHome(dynamic user) => _push(RoleHome(user: user));

  void _push(Widget page) => Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      transitionDuration: const Duration(milliseconds: 350),
    ),
  );

  void _retry() {
    _startedAt = DateTime.now();
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return _buildErrorScreen();
    return _buildSplash();
  }

  Widget _buildSplash() {
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Brand Logo
                  Container(
                    width: 88,
                    height: 88,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.line),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Image.asset(
                      'assets/logo2.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Brand Name
                  const Text(
                    'Bank Sampah',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilah Sampah, Kumpulkan Poin',
                    style: TextStyle(
                      color: AppTheme.subtle,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 56),

                  // Subtle spinner
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.redLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 32,
                    color: AppTheme.red,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Koneksi Terputus',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Periksa jaringan internet Anda.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.subtle,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 180,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Coba Lagi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
