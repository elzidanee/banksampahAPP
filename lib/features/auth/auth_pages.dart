import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:sampahbank/data/models/models.dart';
import 'package:sampahbank/features/admin/admin_shell.dart';
import 'package:sampahbank/features/nasabah/nasabah_shell.dart';

import '../../core/api_client.dart';
import '../../core/exceptions.dart';
import '../../core/session_controller.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets.dart';
import '../../data/auth_repository.dart';
import '../onboarding/onboarding_page.dart';

class AuthScope extends InheritedWidget {
  final SessionController session;
  final ApiClient api;
  final AuthRepository auth;

  const AuthScope({
    super.key,
    required this.session,
    required this.api,
    required this.auth,
    required super.child,
  });

  static AuthScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()!;

  @override
  bool updateShouldNotify(AuthScope oldWidget) =>
      session != oldWidget.session || api != oldWidget.api;
}

// ---------------------------------------------------------------------------
// Login Page
// ---------------------------------------------------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final scope = AuthScope.of(context);
      final (user, token) = await scope.auth.login(
        username: _username.text.trim(),
        password: _password.text,
      );
      await scope.session.saveSession(SessionData(
        token: token,
        role: user.role,
        username: user.username,
        nama: user.nama ?? user.namaUnit,
        alamat: user.alamat,
        telp: user.telp,
        foto: user.foto,
        saldoPoin: user.saldoPoin,
      ));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RoleHome(user: user)));
    } on AppException catch (e) {
      if (mounted) showFeedback(context, e.message, error: true);
    } catch (_) {
      if (mounted) showFeedback(context, 'Login gagal. Silakan coba lagi.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    // Top brand row
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.green.withValues(alpha: .18),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(color: AppTheme.line),
                          ),
                          child: Image.asset('assets/logo2.png', fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Bank Sampah',
                          style: TextStyle(
                            color: AppTheme.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OnboardingPage(isModal: true),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.greenLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.green.withValues(alpha: .2)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.help_outline_rounded, size: 15, color: AppTheme.green),
                                SizedBox(width: 4),
                                Text(
                                  'Panduan',
                                  style: TextStyle(
                                    color: AppTheme.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Selamat\nDatang Kembali',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kelola sampahmu dan raih poin berharga.',
                      style: TextStyle(color: AppTheme.subtle, fontSize: 14, height: 1.45),
                    ),
                    const SizedBox(height: 36),
                    TextFormField(
                      controller: _username,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: AppTheme.ink),
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'Masukkan username',
                        prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.subtle, size: 20),
                      ),
                      validator: Validators.username,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      onFieldSubmitted: (_) => _login(),
                      style: const TextStyle(color: AppTheme.ink),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Masukkan password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.subtle, size: 20),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppTheme.subtle, size: 20),
                        ),
                      ),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Masuk'),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppTheme.line)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: const Text('atau daftar sebagai',
                            style: TextStyle(color: AppTheme.subtle, fontSize: 12)),
                        ),
                        const Expanded(child: Divider(color: AppTheme.line)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _RegisterOptionCard(
                      icon: Icons.person_add_outlined,
                      title: 'Nasabah',
                      subtitle: 'Daftar sebagai nasabah bank sampah',
                      onTap: () => _open(const NasabahRegisterPage()),
                    ),
                    const SizedBox(height: 10),
                    _RegisterOptionCard(
                      icon: Icons.store_outlined,
                      title: 'Unit Bank Sampah',
                      subtitle: 'Daftar unit / pengelola bank sampah',
                      onTap: () => _open(const AdminRegisterPage()),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _RegisterOptionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.line),
          ),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.greenLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.green, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.ink)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppTheme.subtle, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.subtle, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RoleHome
// ---------------------------------------------------------------------------
class RoleHome extends StatelessWidget {
  final UserProfile user;
  const RoleHome({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final sessionRole = AuthScope.of(context).session.current?.role;
    final effectiveRole = (sessionRole != null && sessionRole.isNotEmpty) ? sessionRole : user.role;
    return effectiveRole == 'ADMIN' ? const AdminShell() : const NasabahShell();
  }
}

// ---------------------------------------------------------------------------
// Nasabah Register
// ---------------------------------------------------------------------------
class NasabahRegisterPage extends StatefulWidget {
  const NasabahRegisterPage({super.key});
  @override
  State<NasabahRegisterPage> createState() => _NasabahRegisterPageState();
}

class _NasabahRegisterPageState extends State<NasabahRegisterPage> {
  final _form = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _telp = TextEditingController();
  final _alamat = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _fotoPath;
  bool _agreed = false;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_nama, _telp, _alamat, _username, _password, _confirm]) c.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await picker.ImagePicker().pickImage(source: picker.ImageSource.gallery, imageQuality: 85);
    if (!mounted || result == null) return;
    setState(() => _fotoPath = result.path);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_agreed) { showFeedback(context, 'Setujui syarat dan ketentuan terlebih dahulu.', error: true); return; }
    setState(() => _loading = true);
    try {
      await AuthScope.of(context).auth.registerNasabah(
        username: _username.text.trim(), password: _password.text,
        namaNasabah: _nama.text.trim(), alamat: _alamat.text.trim(),
        telp: _telp.text.trim(), fotoPath: _fotoPath,
      );
      if (!mounted) return;
      showFeedback(context, 'Registrasi berhasil. Silakan login.');
      Navigator.pop(context);
    } on AppException catch (e) {
      if (mounted) showFeedback(context, e.message, error: true);
    } catch (_) {
      if (mounted) showFeedback(context, 'Registrasi gagal.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _RegisterScaffold(
    title: 'Daftar Akun Nasabah',
    form: _form, loading: _loading, onSubmit: _submit,
    children: [
      Center(
        child: Stack(
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: AppTheme.greenGlow,
              ),
              child: CircleAvatar(
                radius: 44, backgroundColor: Colors.transparent,
                backgroundImage: _fotoPath == null ? null : FileImage(File(_fotoPath!)),
                child: _fotoPath == null ? const Icon(Icons.person, size: 42, color: Colors.white) : null,
              ),
            ),
            Positioned(
              right: 0, bottom: 0,
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.bgWhite, shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.line, width: 2),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 15, color: AppTheme.green),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      _field(_nama, 'Nama Lengkap', Icons.badge_outlined),
      _field(_telp, 'No. Telepon', Icons.phone_outlined, validator: Validators.phone),
      _field(_alamat, 'Alamat', Icons.location_on_outlined, maxLines: 2),
      _field(_username, 'Username', Icons.person_outline, validator: Validators.username),
      _field(_password, 'Password', Icons.lock_outline, validator: Validators.password, obscure: true),
      _field(_confirm, 'Konfirmasi Password', Icons.lock_reset_outlined,
        validator: (v) => Validators.confirmPassword(v, _password.text), obscure: true),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.line),
        ),
        child: CheckboxListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          value: _agreed,
          onChanged: (v) => setState(() => _agreed = v ?? false),
          activeColor: AppTheme.green,
          title: const Text('Saya setuju dengan Syarat & Ketentuan',
            style: TextStyle(fontSize: 13, color: AppTheme.inkMedium)),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    ],
  );

  Widget _field(TextEditingController c, String label, IconData icon,
      {String? Function(String?)? validator, bool obscure = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c, obscureText: obscure, maxLines: obscure ? 1 : maxLines,
        style: const TextStyle(color: AppTheme.ink),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.subtle, size: 20),
        ),
        validator: validator ?? (v) => Validators.required(v, label: label),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Admin Register
// ---------------------------------------------------------------------------
class AdminRegisterPage extends StatefulWidget {
  const AdminRegisterPage({super.key});
  @override
  State<AdminRegisterPage> createState() => _AdminRegisterPageState();
}

class _AdminRegisterPageState extends State<AdminRegisterPage> {
  final _form = GlobalKey<FormState>();
  final _unit = TextEditingController();
  final _pengelola = TextEditingController();
  final _telp = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agreed = false;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_unit, _pengelola, _telp, _username, _password, _confirm]) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_agreed) { showFeedback(context, 'Setujui syarat dan ketentuan terlebih dahulu.', error: true); return; }
    setState(() => _loading = true);
    try {
      await AuthScope.of(context).auth.registerAdmin(
        username: _username.text.trim(), password: _password.text,
        namaUnit: _unit.text.trim(), namaPengelola: _pengelola.text.trim(), telp: _telp.text.trim(),
      );
      if (!mounted) return;
      showFeedback(context, 'Unit berhasil terdaftar. Silakan login.');
      Navigator.pop(context);
    } on AppException catch (e) {
      if (mounted) showFeedback(context, e.message, error: true);
    } catch (_) {
      if (mounted) showFeedback(context, 'Registrasi gagal.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _RegisterScaffold(
    title: 'Daftar Unit Bank Sampah',
    form: _form, loading: _loading, onSubmit: _submit,
    children: [
      _field(_unit, 'Nama Unit Bank Sampah', Icons.store_outlined),
      _field(_pengelola, 'Nama Pengelola', Icons.person_outline),
      _field(_telp, 'No. Telepon', Icons.phone_outlined, validator: Validators.phone),
      _field(_username, 'Username', Icons.account_circle_outlined, validator: Validators.username),
      _field(_password, 'Password', Icons.lock_outline, validator: Validators.password, obscure: true),
      _field(_confirm, 'Konfirmasi Password', Icons.lock_reset_outlined,
        validator: (v) => Validators.confirmPassword(v, _password.text), obscure: true),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.line),
        ),
        child: CheckboxListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          value: _agreed,
          onChanged: (v) => setState(() => _agreed = v ?? false),
          activeColor: AppTheme.green,
          title: const Text('Saya setuju dengan Syarat & Ketentuan',
            style: TextStyle(fontSize: 13, color: AppTheme.inkMedium)),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    ],
  );

  Widget _field(TextEditingController c, String label, IconData icon,
      {String? Function(String?)? validator, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c, obscureText: obscure,
        style: const TextStyle(color: AppTheme.ink),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.subtle, size: 20),
        ),
        validator: validator ?? (v) => Validators.required(v, label: label),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _RegisterScaffold
// ---------------------------------------------------------------------------
class _RegisterScaffold extends StatelessWidget {
  final String title;
  final GlobalKey<FormState> form;
  final bool loading;
  final VoidCallback onSubmit;
  final List<Widget> children;

  const _RegisterScaffold({
    required this.title, required this.form,
    required this.loading, required this.onSubmit, required this.children,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgWhite,
    appBar: AppBar(
      title: Text(title),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          ...children,
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              child: loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Daftar Sekarang'),
            ),
          ),
        ],
      ),
    ),
  );
}
