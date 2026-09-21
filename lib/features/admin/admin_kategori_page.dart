import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as picker;

import '../../core/exceptions.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets.dart';
import '../../data/master_repositories.dart';
import '../auth/auth_pages.dart';
import 'models/models.dart';

class AdminKategoriPage extends StatefulWidget {
  const AdminKategoriPage({super.key});

  @override
  State<AdminKategoriPage> createState() => _AdminKategoriPageState();
}

class _AdminKategoriPageState extends State<AdminKategoriPage> {
  List<KategoriSampah> _items = [];
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
      final data = await KategoriRepository(AuthScope.of(context).api).list();
      if (!mounted) return;
      setState(() => _items = data);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({KategoriSampah? existing}) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _KategoriFormPage(existing: existing)),
    );
    if (ok == true) _load();
  }

  Future<void> _delete(KategoriSampah k) async {
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
                    'Hapus Kategori',
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
                'Apakah Anda yakin ingin menghapus "${k.namaKategori}"?\n\nTindakan ini tidak dapat dibatalkan.',
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
      await KategoriRepository(AuthScope.of(context).api).delete(k.id);
      if (!mounted) return;
      showFeedback(context, 'Kategori dihapus.');
      _load();
    } on AppException catch (e) {
      if (mounted) showFeedback(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_kategori_add',
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
              final k = _items[i];
              return Card(
                child: ListTile(
                  leading: SafeImage(
                    url: k.foto,
                    fallbackIcon: Icons.recycling_outlined,
                  ),
                  title: Text(
                    k.namaKategori,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${Formatters.rupiah(k.hargaPerKg)}/kg • ${Formatters.poin(k.poinPerKg)} poin/kg • ${k.jenis}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _openForm(existing: k);
                      if (v == 'delete') _delete(k);
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

class _KategoriFormPage extends StatefulWidget {
  final KategoriSampah? existing;
  const _KategoriFormPage({this.existing});

  @override
  State<_KategoriFormPage> createState() => _KategoriFormPageState();
}

class _KategoriFormPageState extends State<_KategoriFormPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _harga;
  late final TextEditingController _poin;
  String _jenis = 'plastik';
  String? _fotoPath;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nama = TextEditingController(text: e?.namaKategori ?? '');
    _harga = TextEditingController(
      text: e != null ? e.hargaPerKg.toStringAsFixed(0) : '',
    );
    _poin = TextEditingController(
      text: e != null ? e.poinPerKg.toStringAsFixed(0) : '',
    );
    _jenis = e?.jenis ?? 'plastik';
  }

  @override
  void dispose() {
    _nama.dispose();
    _harga.dispose();
    _poin.dispose();
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
      final repo = KategoriRepository(AuthScope.of(context).api);
      final harga = double.parse(_harga.text.trim());
      final poin = double.parse(_poin.text.trim());
      if (widget.existing != null) {
        await repo.update(
          widget.existing!.id,
          namaKategori: _nama.text.trim(),
          hargaPerKg: harga,
          poinPerKg: poin,
          jenis: _jenis,
          fotoPath: _fotoPath,
        );
      } else {
        await repo.create(
          namaKategori: _nama.text.trim(),
          hargaPerKg: harga,
          poinPerKg: poin,
          jenis: _jenis,
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
        title: Text(
          widget.existing != null ? 'Edit Kategori' : 'Tambah Kategori',
        ),
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
              decoration: const InputDecoration(labelText: 'Nama Kategori'),
              validator: (v) => Validators.required(v, label: 'Nama'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _harga,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga per kg (Rp)'),
              validator: (v) => Validators.positiveNumber(v, label: 'Harga'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _poin,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Poin per kg'),
              validator: (v) => Validators.positiveNumber(v, label: 'Poin'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _jenis,
              decoration: const InputDecoration(labelText: 'Jenis Sampah'),
              items: [
                for (final j in KategoriSampah.jenisOptions)
                  DropdownMenuItem(value: j, child: Text(j)),
              ],
              onChanged: (v) => setState(() => _jenis = v ?? 'plastik'),
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
