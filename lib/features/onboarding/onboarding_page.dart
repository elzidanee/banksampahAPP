import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../auth/auth_pages.dart';

const _kOnboardingDone = 'onboarding_done_v2';

Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDone) ?? false;
}

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDone, true);
}

Future<void> resetOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kOnboardingDone);
}

class OnboardingPage extends StatefulWidget {
  final bool isModal;
  const OnboardingPage({super.key, this.isModal = false});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _current = 0;

  late final List<AnimationController> _enterCtrl;
  late final List<Animation<double>> _enterFade;
  late final List<Animation<Offset>> _enterSlide;

  static const _data = [
    _SlideData(
      title: 'Pilah & Setor Sampah',
      subtitle:
          'Pilah sampah rumah tangga dan setor ke bank sampah terdekat.\nSetiap gram sampahmu bernilai kebaikan!',
      accentColor: AppTheme.green,
      bgColor: AppTheme.greenLight,
      imagePath: 'assets/illustrations/onboarding_sort.jpg',
    ),
    _SlideData(
      title: 'Kumpulkan Poin',
      subtitle:
          'Setiap setoran sampah dikonversi otomatis menjadi poin digital\nyang tersimpan aman di saldo akunmu.',
      accentColor: AppTheme.amber,
      bgColor: AppTheme.amberLight,
      imagePath: 'assets/illustrations/onboarding_points.jpg',
    ),
    _SlideData(
      title: 'Tukar Hadiah Menarik',
      subtitle:
          'Tukarkan akumulasi poin dengan beragam hadiah menarik\nmulai dari sembako, voucher, hingga merchandise!',
      accentColor: AppTheme.blue,
      bgColor: AppTheme.blueLight,
      imagePath: 'assets/illustrations/onboarding_rewards.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _enterCtrl = List.generate(
      _data.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _enterFade = _enterCtrl
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
    _enterSlide = _enterCtrl
        .map(
          (c) => Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
              .animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)),
        )
        .toList();

    _enterCtrl[0].forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in _enterCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (_current < _data.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await markOnboardingDone();
    if (!mounted) return;
    if (widget.isModal) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = _data[_current];
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Skip / Tutup
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    widget.isModal ? 'Tutup' : 'Lewati',
                    style: const TextStyle(
                      color: AppTheme.subtle,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Page carousel
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) {
                  setState(() => _current = i);
                  _enterCtrl[i].forward(from: 0);
                },
                itemCount: _data.length,
                itemBuilder: (_, i) => FadeTransition(
                  opacity: _enterFade[i],
                  child: SlideTransition(
                    position: _enterSlide[i],
                    child: _SlideView(
                      data: _data[i],
                      pageIndex: i,
                    ),
                  ),
                ),
              ),
            ),

            // Dots Indicator & Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_data.length, (i) {
                      final active = i == _current;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? slide.accentColor : AppTheme.lineStrong,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: slide.accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _next,
                      child: Text(
                        _current == _data.length - 1
                            ? 'Mulai Sekarang'
                            : 'Lanjut',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color bgColor;
  final String imagePath;

  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.bgColor,
    required this.imagePath,
  });
}

class _SlideView extends StatelessWidget {
  final _SlideData data;
  final int pageIndex;

  const _SlideView({
    required this.data,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            // High resolution flat vector illustration
            Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: data.accentColor.withValues(alpha: .12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  data.imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Step Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: data.accentColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: data.accentColor.withValues(alpha: .3)),
              ),
              child: Text(
                _labelFor(pageIndex),
                style: TextStyle(
                  color: data.accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),

            // Subtitle
            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.subtle,
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(int i) => switch (i) {
    0 => 'LANGKAH 1',
    1 => 'LANGKAH 2',
    _ => 'LANGKAH 3',
  };
}
