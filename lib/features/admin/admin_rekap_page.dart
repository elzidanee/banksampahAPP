import 'package:flutter/material.dart';

import '../../core/exceptions.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/transaction_repositories.dart';
import '../auth/auth_pages.dart';
import 'models/models.dart';

class AdminRekapPage extends StatefulWidget {
  const AdminRekapPage({super.key});

  @override
  State<AdminRekapPage> createState() => _AdminRekapPageState();
}

class _AdminRekapPageState extends State<AdminRekapPage> {
  RekapBulanan? _data;
  bool _loading = true;
  String? _error;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

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
      final repo = RekapRepository(AuthScope.of(context).api);
      final data = await repo.monthly(Formatters.bulanQuery(_month));
      if (!mounted) return;
      setState(() => _data = data);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.green,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text(
                'Rekapitulasi Bulanan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final picked = await pickMonth(context, _month);
                  if (picked == null) return;
                  setState(() => _month = picked);
                  _load();
                },
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: Text(
                  '${Formatters.monthNames[_month.month - 1]} ${_month.year}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StateContainer(
            loading: _loading,
            error: _error,
            isEmpty: false,
            onRetry: _load,
            child: _data == null
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _summaryCard(
                        'Total Tonase',
                        '${Formatters.kg(_data!.totalKg)} kg (${_data!.totalTon} ton)',
                      ),
                      _summaryCard(
                        'Estimasi Pembayaran',
                        Formatters.rupiah(_data!.totalEstimasiPembayaran),
                      ),
                      _summaryCard(
                        'Poin Diterbitkan',
                        Formatters.poin(_data!.totalPoinDiterbitkan),
                      ),
                      _summaryCard(
                        'Penukaran Poin',
                        '${_data!.totalTransaksiPenukaran} transaksi • ${Formatters.poin(_data!.totalPoinTerpakai)} poin',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Breakdown Jenis Sampah',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      for (final entry in _data!.breakdownJenis.entries)
                        _breakdownCard(entry.key, entry.value),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.line),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.subtle, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ],
    ),
  );

  Widget _breakdownCard(String jenis, RekapJenis data) {
    final isEmpty = data.tonaseKg == 0;
    final content = Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_breakdownIcon(jenis), color: AppTheme.green, size: 22),
                const SizedBox(width: 10),
                Text(
                  _titleCase(jenis),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _metric('Berat', '${Formatters.kg(data.tonaseKg)} kg'),
                _metric('Rupiah', Formatters.rupiah(data.rupiah)),
                _metric('Poin', '${Formatters.poin(data.poin)} poin'),
              ],
            ),
          ],
        ),
      ),
    );
    return isEmpty ? Opacity(opacity: .5, child: content) : content;
  }

  Widget _metric(String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.subtle, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  IconData _breakdownIcon(String jenis) => switch (jenis.toLowerCase()) {
    'plastik' => Icons.local_drink_outlined,
    'kertas' => Icons.description_outlined,
    'logam' => Icons.settings_outlined,
    'kaca' => Icons.wine_bar_outlined,
    _ => Icons.recycling_outlined,
  };

  String _titleCase(String value) => value.isEmpty
      ? value
      : '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}
