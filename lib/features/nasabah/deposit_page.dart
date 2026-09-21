import 'package:flutter/material.dart';
import 'package:sampahbank/data/models/models.dart';

import '../../core/exceptions.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets.dart';
import '../../data/master_repositories.dart';
import '../../data/transaction_repositories.dart';
import '../auth/auth_pages.dart';

/// Screen 4 — Ajukan Penyetoran Sampah (multi-item with live point preview).
class DepositPage extends StatefulWidget {
  const DepositPage({super.key});

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  List<KategoriSampah> _categories = [];
  bool _loadingCategories = true;
  bool _submitting = false;
  String? _error;

  DateTime _tanggal = DateTime.now();
  final _catatan = TextEditingController();

  /// One row per chosen item: category id + berat controller.
  final List<_ItemRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _catatan.dispose();
    for (final r in _rows) {
      r.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _error = null;
    });
    try {
      final repo = KategoriRepository(AuthScope.of(context).api);
      final data = await repo.list();
      if (!mounted) return;
      setState(() => _categories = data);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat kategori sampah.');
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  double _poinPerKg(String? kategoriId) {
    final k = _categories.where((c) => c.id == kategoriId).firstOrNull;
    return k?.poinPerKg ?? 0;
  }

  double get _estimasiTotal {
    double total = 0;
    for (final r in _rows) {
      final berat = double.tryParse(r.controller.text.replaceAll(',', '.'));
      if (r.kategoriId != null && berat != null && berat > 0) {
        total += berat * _poinPerKg(r.kategoriId);
      }
    }
    return total;
  }

  void _addRow() {
    final available = _categories
        .where((category) => !_rows.any((row) => row.kategoriId == category.id))
        .toList();
    if (available.isEmpty) {
      showFeedback(context, 'Semua kategori sudah dipilih.', error: true);
      return;
    }
    setState(() => _rows.add(_ItemRow()));
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].controller.dispose();
      _rows.removeAt(index);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(_tanggal.year - 1),
      lastDate: DateTime(_tanggal.year + 1),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.green,
            surface: AppTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _submit() async {
    // Validate all rows client-side before hitting the API.
    final validItems = <({String kategoriSampahId, double beratKg})>[];
    String? rowError;
    for (final r in _rows) {
      final berat = double.tryParse(r.controller.text.replaceAll(',', '.'));
      if (r.kategoriId == null) {
        rowError = 'Setiap baris harus memilih kategori sampah.';
      } else if (berat == null || berat <= 0) {
        rowError = 'Estimasi berat harus berupa angka lebih dari 0.';
      }
      if (rowError != null) break;
      validItems.add((kategoriSampahId: r.kategoriId!, beratKg: berat!));
    }
    if (rowError != null) {
      showFeedback(context, rowError, error: true);
      return;
    }
    if (validItems.isEmpty) {
      showFeedback(context, 'Tambahkan minimal satu item sampah.', error: true);
      return;
    }
    if (_catatan.text.trim().isEmpty) {
      showFeedback(context, 'Catatan pengajuan wajib diisi.', error: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = DepositRepository(AuthScope.of(context).api);
      final result = await repo.submit(
        tanggal: _tanggal.toUtc().toIso8601String(),
        catatan: _catatan.text.trim(),
        items: validItems,
      );
      if (!mounted) return;
      showFeedback(
        context,
        'Pengajuan ${result.kodeSetor} berhasil dibuat (estimasi ${Formatters.poin(result.totalPoin)} poin).',
      );
      setState(() {
        for (final r in _rows) {
          r.controller.dispose();
        }
        _rows.clear();
        _catatan.clear();
        _tanggal = DateTime.now();
      });
    } on AppException catch (e) {
      if (mounted) showFeedback(context, e.message, error: true);
    } catch (_) {
      if (mounted) {
        showFeedback(
          context,
          'Gagal mengirim pengajuan. Coba lagi.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Penyetoran')),
      body: _loadingCategories
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.green),
            )
          : _error != null
          ? StateContainer(
              loading: false,
              error: _error,
              onRetry: _loadCategories,
              child: const SizedBox.shrink(),
            )
          : _categories.isEmpty && _error == null
          ? const StateContainer(
              loading: false,
              isEmpty: true,
              emptyTitle: 'Kategori Belum Tersedia',
              emptyMessage:
                  'Admin belum menambahkan kategori sampah. Coba lagi nanti.',
              child: SizedBox.shrink(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Tanggal Penyetoran',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      Formatters.date(_tanggal.toIso8601String()),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text(
                      'Pilih Sampah',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addRow,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah Sampah'),
                    ),
                  ],
                ),
                ..._buildRows(),
                const Divider(height: 28),
                Row(
                  children: [
                    const Text(
                      'Estimasi Total Poin',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${Formatters.poin(_estimasiTotal)} Poin',
                      style: const TextStyle(
                        color: AppTheme.green,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Catatan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _catatan,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Tulis catatan pengajuan...',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined, size: 18),
                  label: const Text('AJUKAN'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Estimasi poin dihitung dari poin/kg kategori dan dapat berubah setelah penimbangan resmi oleh admin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppTheme.subtle),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildRows() => [for (var i = 0; i < _rows.length; i++) _row(i)];

  Widget _row(int i) {
    final r = _rows[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: r.kategoriId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Pilih kategori sampah',
                  ),
                  items: [
                    for (final category in _categories)
                      if (!_rows.any(
                        (other) =>
                            other != r && other.kategoriId == category.id,
                      ))
                        DropdownMenuItem(
                          value: category.id,
                          child: Text(
                            category.namaKategori,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  ],
                  onChanged: (value) => setState(() {
                    r.kategoriId = value;
                  }),
                ),
              ),
              IconButton(
                onPressed: () => _removeRow(i),
                icon: const Icon(Icons.delete_outline, color: AppTheme.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: r.controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Estimasi berat (kg)',
                  ),
                  onChanged: (_) => setState(() {}), // live point preview
                  validator: (v) =>
                      Validators.positiveNumber(v, label: 'Berat'),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Poin ${Formatters.poin(_rowPoin(r))}',
                style: const TextStyle(
                  color: AppTheme.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _rowPoin(_ItemRow r) {
    final berat = double.tryParse(r.controller.text.replaceAll(',', '.'));
    if (r.kategoriId == null || berat == null || berat <= 0) return 0;
    return berat * _poinPerKg(r.kategoriId);
  }
}

class _ItemRow {
  String? kategoriId;
  final TextEditingController controller = TextEditingController();
}
