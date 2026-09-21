import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as picker;

import '../../core/exceptions.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets.dart';
import '../../data/master_repositories.dart';
import '../auth/auth_pages.dart';
import 'models/models.dart';

class AdminHadiahPage extends StatefulWidget {
  const AdminHadiahPage({super.key});

  @override
  State<AdminHadiahPage> createState() => _AdminHadiahPageState();
}

class _AdminHadiahPageState extends State<AdminHadiahPage> {
  List<Hadiah> _items = [];
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
      final data = await HadiahRepository(AuthScope.of(context).api).list();
      if (!mounted) return;
      setState(() => _items = data);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({Hadiah? existing}) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _HadiahFormPage(existing: existing)),
    );
    if (ok == true) _load();
  }

  Future<void> _delete(Hadiah h) async {
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
                    'Hapus Hadiah',
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
                'Apakah Anda yakin ingin menghapus "${h.namaHadiah}"?\n\nTindakan ini tidak dapat dibatalkan.',
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
    try {
      await HadiahRepository(AuthScope.of(context).api).delete(h.id);
      if (!mounted) return;
      showFeedback(context, 'Hadiah dihapus.');
      _load();
    } on AppException catch (e) {
      if (mounted) showFeedback(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_hadiah_add',
        onPressed: () => _openForm(),
        backgroundColor: AppTheme.green,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: StateContainer(
        loading: _loading,
        error: _error,
        isEmpty: _items.isEmpty,
        onRetry: _load,
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.green,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final h = _items[i];
              return Card(
                child: ListTile(
                  leading: SafeImage(
                    url: h.foto,
                    fallbackIcon: Icons.card_giftcard,
                  ),
                  title: Text(
                    h.namaHadiah,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${Formatters.poin(h.poinDibutuhkan)} poin • Stok ${h.stok}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _openForm(existing: h);
                      if (v == 'delete') _delete(h);
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

class _HadiahFormPage extends StatefulWidget {
  final Hadiah? existing;
  const _HadiahFormPage({this.existing});

  @override
  State<_HadiahFormPage> createState() => _HadiahFormPageState();
}

class _HadiahFormPageState extends State<_HadiahFormPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _poin;
  late final TextEditingController _stok;
  String? _fotoPath;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nama = TextEditingController(text: e?.namaHadiah ?? '');
    _poin = TextEditingController(
      text: e != null ? e.poinDibutuhkan.toStringAsFixed(0) : '',
    );
    _stok = TextEditingController(text: e != null ? '${e.stok}' : '');
  }

  @override
  void dispose() {
    _nama.dispose();
    _poin.dispose();
    _stok.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final r = await picker.ImagePicker().pickImage(
      source: picker.ImageSource.gallery,
      imageQuality: 85,
    );
    if (r != null) setState(() => _fotoPath = r.path);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = HadiahRepository(AuthScope.of(context).api);
      final poin = double.parse(_poin.text.trim());
      final stok = int.parse(_stok.text.trim());
      if (widget.existing != null) {
        await repo.update(
          widget.existing!.id,
          namaHadiah: _nama.text.trim(),
          poinDibutuhkan: poin,
          stok: stok,
          fotoPath: _fotoPath,
        );
      } else {
        await repo.create(
          namaHadiah: _nama.text.trim(),
          poinDibutuhkan: poin,
          stok: stok,
          fotoPath: _fotoPath,
        );
      }
      if (!mounted) return;
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
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Edit Hadiah' : 'Tambah Hadiah'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: SafeImage(
                  url: _fotoPath == null ? widget.existing?.foto : null,
                  size: 80,
                  fallbackIcon: Icons.add_a_photo_outlined,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(labelText: 'Nama Hadiah'),
              validator: (v) => Validators.required(v, label: 'Nama'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _poin,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Poin Dibutuhkan'),
              validator: (v) => Validators.positiveNumber(v, label: 'Poin'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stok,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stok'),
              validator: (v) => Validators.nonNegativeInt(v, label: 'Stok'),
            ),
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
                  : const Text('SIMPAN'),
            ),
          ],
        ),
      ),
    );
  }
}
