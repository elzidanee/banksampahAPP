import 'dart:async' as async;
import 'dart:math' as math;

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
      statusBarIconBrightness: Brightness.light,
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
// Splash Page
// ---------------------------------------------------------------------------

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  static const _minDuration = Duration(seconds: 3);

  // Logo animations
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  // Rings pulse
  late final AnimationController _ringCtrl;
  late final Animation<double> _ring1;
  late final Animation<double> _ring2;

  // Text slide up
  late final AnimationController _textCtrl;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;

  // Floating particles
  late final AnimationController _particleCtrl;

  // Progress bar
  late final AnimationController _progressCtrl;

  late DateTime _startedAt;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();

    // Logo: springs in
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.4, curve: Curves.easeIn));

    // Ring pulses (staggered)
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _ring1 = Tween<double>(begin: 0.7, end: 1.35)
        .animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));
    _ring2 = Tween<double>(begin: 0.7, end: 1.65)
        .animate(CurvedAnimation(parent: _ringCtrl,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut)));

    // Text slides up
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn);

    // Particles spin forever
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();

    // Progress bar fills over minDuration
    _progressCtrl = AnimationController(vsync: this, duration: _minDuration)
      ..forward();

    // Chain: logo -> ring -> text
    _logoCtrl.forward().then((_) {
      _ringCtrl.forward();
      _textCtrl.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _ringCtrl.dispose();
    _textCtrl.dispose();
    _particleCtrl.dispose();
    _progressCtrl.dispose();
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
      transitionDuration: const Duration(milliseconds: 500),
    ),
  );

  void _retry() {
    _startedAt = DateTime.now();
    _progressCtrl.forward(from: 0);
    setState(() { _hasError = false; _errorMessage = null; });
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return _buildErrorScreen();
    return _buildSplash();
  }

  Widget _buildSplash() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E8A40),
              Color(0xFF2E9E50),
              Color(0xFF3DB866),
              Color(0xFF1A6B32),
            ],
            stops: [0.0, 0.35, 0.70, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Floating particles background
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ParticlePainter(_particleCtrl.value),
              ),
            ),

            // Center content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rings + Logo
                  SizedBox(
                    width: 200, height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring 2 (slower)
                        AnimatedBuilder(
                          animation: _ring2,
                          builder: (_, __) => Transform.scale(
                            scale: _ring2.value,
                            child: Opacity(
                              opacity: (1.0 - (_ring2.value - 0.7) / 0.95).clamp(0.0, 0.4),
                              child: Container(
                                width: 160, height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Inner ring 1
                        AnimatedBuilder(
                          animation: _ring1,
                          builder: (_, __) => Transform.scale(
                            scale: _ring1.value,
                            child: Opacity(
                              opacity: (1.0 - (_ring1.value - 0.7) / 0.65).clamp(0.0, 0.55),
                              child: Container(
                                width: 130, height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // White circle backdrop
                        Container(
                          width: 110, height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: .2),
                          ),
                        ),
                        // Logo
                        FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: Container(
                              width: 96, height: 96,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .18),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Image.asset('assets/logo2.png', fit: BoxFit.contain),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // App name + tagline
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          const Text(
                            'Bank Sampah',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: .35)),
                            ),
                            child: const Text(
                              'Sampah Bernilai • Bumi Lestari',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom progress bar
            Positioned(
              left: 0, right: 0, bottom: 48,
              child: FadeTransition(
                opacity: _textFade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 64),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _progressCtrl,
                        builder: (_, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progressCtrl.value,
                            backgroundColor: Colors.white.withValues(alpha: .25),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Memuat aplikasi...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E8A40), Color(0xFF2E9E50), Color(0xFF1A6B32)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_off_rounded, size: 38, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tidak Dapat Terhubung',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage ?? 'Periksa koneksi internet Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w700)),
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
}

// ---------------------------------------------------------------------------
// Particle Painter
// ---------------------------------------------------------------------------
class _ParticlePainter extends CustomPainter {
  final double progress;
  static final _rng = math.Random(42);
  static final _particles = List.generate(18, (i) => _Particle(
    x: _rng.nextDouble(),
    y: _rng.nextDouble(),
    size: 3 + _rng.nextDouble() * 8,
    speed: 0.03 + _rng.nextDouble() * 0.07,
    phase: _rng.nextDouble(),
  ));

  const _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in _particles) {
      final angle = (progress * p.speed * math.pi * 2) + p.phase * math.pi * 2;
      final dx = p.x * size.width + math.cos(angle) * 18;
      final dy = (p.y + progress * p.speed * 0.5) % 1.0 * size.height;
      final opacity = (0.08 + math.sin(angle) * 0.05).clamp(0.03, 0.15);
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(dx, dy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, size, speed, phase;
  const _Particle({required this.x, required this.y, required this.size, required this.speed, required this.phase});
}
