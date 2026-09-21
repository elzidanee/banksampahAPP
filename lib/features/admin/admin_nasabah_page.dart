import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as picker;

import '../../core/exceptions.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets.dart';
import '../../data/master_repositories.dart';
import '../auth/auth_pages.dart';
import 'models/models.dart';

class AdminNasabahPage extends StatefulWidget {
  const AdminNasabahPage({super.key});

  @override
  State<AdminNasabahPage> createState() => _AdminNasabahPageState();
}

class _AdminNasabahPageState extends State<AdminNasabahPage> {
  List<NasabahAdmin> _items = [];
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
      final repo = NasabahAdminRepository(AuthScope.of(context).api);
      final data = await repo.list();
      if (!mounted) return;
      setState(() => _items = data);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat data nasabah.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({NasabahAdmin? existing}) async {
    NasabahAdmin? formData = existing;
    if (existing != null) {
      try {
        formData = await NasabahAdminRepository(
          AuthScope.of(context).api,
        ).detail(existing.id);
      } on AppException catch (e) {
        if (mounted) showFeedback(context, e.message, error: true);
        return;
      }
    }

    if (!mounted) return;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _NasabahFormPage(existing: formData)),
    );
    if (!mounted) return;
    if (ok == true) await _load();
  }

  Future<void> _delete(NasabahAdmin n) async {
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
                      Icons.delete_outline_rounded,
                      color: AppTheme.red,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Hapus Nasabah',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Apakah Anda yakin ingin menghapus "${n.namaNasabah}" dari sistem?\n\nTindakan ini tidak dapat dibatalkan.',
                style: const TextStyle(
                  color: AppTheme.subtle,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
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
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Hapus'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    try {
      await NasabahAdminRepository(AuthScope.of(context).api).delete(n.id);
      if (!mounted) return;
      showFeedback(context, 'Nasabah berhasil dihapus.');
      _load();
    } on AppException catch (e) {
      if (mounted) showFeedback(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_nasabah_add',
        onPressed: () => _openForm(),
        backgroundColor: AppTheme.green,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Tambah'),
      ),
      body: StateContainer(
        loading: _loading,
        error: _error,
        isEmpty: _items.isEmpty,
        emptyTitle: 'Belum Ada Nasabah',
        emptyMessage: 'Tambahkan nasabah bank sampah melalui tombol Tambah.',
        onRetry: _load,
        child: RefreshIndicator(
          color: AppTheme.green,
          onRefresh: _load,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final n = _items[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.greenLight,
                    backgroundImage: resolveImageUrl(n.foto) != null
                        ? NetworkImage(resolveImageUrl(n.foto)!)
                        : null,
                    child: resolveImageUrl(n.foto) == null
                        ? const Icon(Icons.person, color: AppTheme.green)
                        : null,
                  ),
                  title: Text(
                    n.namaNasabah,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '@${n.username ?? '-'} • ${Formatters.poin(n.saldoPoin)} poin',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _openForm(existing: n);
                      if (v == 'delete') _delete(n);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NasabahFormPage extends StatefulWidget {
  final NasabahAdmin? existing;
  const _NasabahFormPage({this.existing});

  @override
  State<_NasabahFormPage> createState() => _NasabahFormPageState();
}

class _NasabahFormPageState extends State<_NasabahFormPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _telp;
  late final TextEditingController _alamat;
  late final TextEditingController _username;
  late final TextEditingController _password;
  String? _fotoPath;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nama = TextEditingController(text: e?.namaNasabah ?? '');
    _telp = TextEditingController(text: e?.telp ?? '');
    _alamat = TextEditingController(text: e?.alamat ?? '');
    _username = TextEditingController(text: e?.username ?? '');
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _nama.dispose();
    _telp.dispose();
    _alamat.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await picker.ImagePicker().pickImage(
      source: picker.ImageSource.gallery,
      imageQuality: 85,
    );
    if (!mounted) return;
    if (result != null) setState(() => _fotoPath = result.path);
  }

  void _previewPhoto() {
    final imageUrl = resolveImageUrl(widget.existing?.foto);
    if (_fotoPath == null && imageUrl == null) return;

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: _fotoPath != null
                    ? Image.file(File(_fotoPath!), fit: BoxFit.contain)
                    : Image.network(imageUrl!, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              tooltip: 'Tutup preview',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = NasabahAdminRepository(AuthScope.of(context).api);
      final fallbackTanggalLahir =
          widget.existing?.tanggalLahir ?? '2000-01-01';

      if (_isEdit) {
        await repo.update(
          widget.existing!.id,
          namaLengkap: _nama.text.trim(),
          alamat: _alamat.text.trim(),
          noTelepon: _telp.text.trim(),
          tanggalLahir: fallbackTanggalLahir,
          fotoPath: _fotoPath,
        );
      } else {
        await repo.create(
          username: _username.text.trim(),
          password: _password.text,
          namaNasabah: _nama.text.trim(),
          alamat: _alamat.text.trim(),
          telp: _telp.text.trim(),
          fotoPath: _fotoPath,
        );
      }
      if (!mounted) return;
      showFeedback(
        context,
        _isEdit ? 'Data nasabah diperbarui.' : 'Nasabah ditambahkan.',
      );
      Navigator.pop(context, true);
    } on AppException catch (e) {
      if (mounted) showFeedback(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Nasabah' : 'Tambah Nasabah')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _previewPhoto,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.greenLight,
                      backgroundImage: _fotoPath != null
                          ? FileImage(File(_fotoPath!))
                          : (resolveImageUrl(widget.existing?.foto) != null
                                ? NetworkImage(
                                    resolveImageUrl(widget.existing!.foto)!,
                                  )
                                : null),
                      child:
                          _fotoPath == null &&
                              resolveImageUrl(widget.existing?.foto) == null
                          ? const Icon(
                              Icons.person_outline,
                              color: AppTheme.green,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _pickPhoto,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Pilih Foto'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(labelText: 'Nama Nasabah'),
              validator: (v) => Validators.required(v, label: 'Nama'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telp,
              decoration: const InputDecoration(labelText: 'No. Telepon'),
              validator: Validators.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _alamat,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Alamat'),
              validator: (v) => Validators.required(v, label: 'Alamat'),
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: Validators.username,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: Validators.password,
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEdit ? 'SIMPAN' : 'TAMBAH'),
            ),
          ],
        ),
      ),
    );
  }
}
