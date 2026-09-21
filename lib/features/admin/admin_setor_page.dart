import 'package:flutter/material.dart';

import '../../core/exceptions.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/master_repositories.dart';
import '../../data/transaction_repositories.dart';
import '../auth/auth_pages.dart';
import '../shared/receipt_pages.dart';
import 'models/models.dart';

class AdminSetorPage extends StatefulWidget {
  const AdminSetorPage({super.key});

  @override
  State<AdminSetorPage> createState() => _AdminSetorPageState();
}

class _AdminSetorPageState extends State<AdminSetorPage> {
  List<SetorSampah> _items = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  static const _statuses = [
    null,
    'menunggu_konfirmasi',
    'diverifikasi',
    'selesai',
    'ditolak',
  ];

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
      final repo = DepositRepository(AuthScope.of(context).api);
      final data = await repo.adminList(
        status: _statusFilter,
        bulan: Formatters.bulanQuery(_month),
      );
      if (!mounted) return;
      setState(() => _items = data);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify(SetorSampah s) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _VerifySetorPage(setor: s)),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filter Status',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua')),
                    for (final st in _statuses.skip(1))
                      DropdownMenuItem(
                        value: st,
                        child: Text(StatusStyle.setor(st!).$1),
                      ),
                  ],
                  onChanged: (v) {
                    setState(() => _statusFilter = v);
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Pilih bulan',
                onPressed: () async {
                  final picked = await pickMonth(context, _month);
                  if (picked == null) return;
                  setState(() => _month = picked);
                  _load();
                },
                icon: const Icon(Icons.calendar_month_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          child: StateContainer(
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
                  final s = _items[i];
                  final style = StatusStyle.setor(s.status);
                  return Card(
                    child: ListTile(
                      title: Text(
                        s.kodeSetor,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${s.namaNasabah ?? '-'} • ${Formatters.date(s.tanggal)} • ${Formatters.kg(s.totalBeratKg)} kg',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: StatusChip(label: style.$1, color: style.$2),
                      onTap: () {
                        if (s.status == 'menunggu_konfirmasi' ||
                            s.status == 'diverifikasi') {
                          _verify(s);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SetorReceiptPage(setorId: s.id),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VerifySetorPage extends StatefulWidget {
  final SetorSampah setor;
  const _VerifySetorPage({required this.setor});

  @override
  State<_VerifySetorPage> createState() => _VerifySetorPageState();
}

class _VerifySetorPageState extends State<_VerifySetorPage> {
  SetorSampah? _detail;
  bool _loading = true;
  String _status = 'selesai';
  final _catatan = TextEditingController();
  final Map<int, TextEditingController> _weights = {};
  final Map<int, String> _categoryIds = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
  }

  @override
  void dispose() {
    _catatan.dispose();
    for (final c in _weights.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      final repo = DepositRepository(AuthScope.of(context).api);
      final d = await repo.detail(widget.setor.id);
      final categories = await KategoriRepository(
        AuthScope.of(context).api,
      ).list();
      if (!mounted) return;
      setState(() {
        _detail = d;
        for (var index = 0; index < d.items.length; index++) {
          final item = d.items[index];
          final categoryId = item.kategoriSampahId.isNotEmpty
              ? item.kategoriSampahId
              : _findCategoryId(item, categories);
          if (categoryId != null) _categoryIds[index] = categoryId;
          _weights[index] = TextEditingController(
            text: item.beratKg.toString(),
          );
        }
      });
    } on AppException catch (e) {
      if (!mounted) return;
      showFeedback(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_catatan.text.trim().isEmpty) {
      showFeedback(context, 'Catatan admin wajib diisi.', error: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final itemsReal = <({String kategoriSampahId, double beratKgReal})>[];
      if (_status != 'ditolak' && _detail != null) {
        for (var index = 0; index < _detail!.items.length; index++) {
          final item = _detail!.items[index];
          final categoryId = _categoryIds[index];
          if (categoryId == null) {
            showFeedback(
              context,
              'Kategori ${item.namaKategori ?? 'sampah'} tidak ditemukan.',
              error: true,
            );
            setState(() => _submitting = false);
            return;
          }
          final c = _weights[index];
          final berat = double.tryParse(c?.text.replaceAll(',', '.') ?? '');
          if (berat == null || berat <= 0) {
            showFeedback(context, 'Berat real harus valid.', error: true);
            setState(() => _submitting = false);
            return;
          }
          itemsReal.add((kategoriSampahId: categoryId, beratKgReal: berat));
        }
      }
      await DepositRepository(AuthScope.of(context).api).verify(
        widget.setor.id,
        status: _status,
        catatanAdmin: _catatan.text.trim(),
        itemsReal: _status == 'ditolak' ? null : itemsReal,
      );
      if (!mounted) return;
      showFeedback(context, 'Verifikasi berhasil disimpan.');
      Navigator.pop(context, true);
    } on AppException catch (e) {
      if (mounted) showFeedback(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verifikasi ${widget.setor.kodeSetor}')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.green),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Nasabah: ${_detail?.namaNasabah ?? widget.setor.namaNasabah ?? '-'}',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status Baru'),
                  items: const [
                    DropdownMenuItem(
                      value: 'diverifikasi',
                      child: Text('Diverifikasi'),
                    ),
                    DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
                    DropdownMenuItem(value: 'ditolak', child: Text('Ditolak')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'selesai'),
                ),
                const SizedBox(height: 12),
                if (_detail != null && _status != 'ditolak')
                  ..._detail!.items.asMap().entries.map((entry) {
                    final item = entry.value;
                    final c = _weights[entry.key]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: c,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText:
                              'Berat real (kg) — ${item.namaKategori ?? item.kategoriSampahId}',
                        ),
                      ),
                    );
                  }),
                TextField(
                  controller: _catatan,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Catatan Admin'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('SIMPAN VERIFIKASI'),
                ),
              ],
            ),
    );
  }

  String? _findCategoryId(SetorItem item, List<KategoriSampah> categories) {
    final name = item.namaKategori?.trim().toLowerCase();
    final jenis = item.jenis?.trim().toLowerCase();
    final matches = categories.where((category) {
      final sameName =
          name != null &&
          name.isNotEmpty &&
          category.namaKategori.trim().toLowerCase() == name;
      final sameJenis =
          jenis != null &&
          jenis.isNotEmpty &&
          category.jenis.trim().toLowerCase() == jenis;
      return sameName || (name == null && sameJenis);
    }).toList();
    return matches.length == 1 ? matches.single.id : null;
  }
}
