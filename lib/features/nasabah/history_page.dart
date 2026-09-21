import 'package:flutter/material.dart';

import '../../core/exceptions.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/transaction_repositories.dart';
import '../auth/auth_pages.dart';
import '../shared/receipt_pages.dart';
import 'models/models.dart';

/// Screen 5 — Histori penyetoran sampah dengan filter bulan.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<SetorSampah> _items = [];
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
      final repo = DepositRepository(AuthScope.of(context).api);
      final data = await repo.mine(bulan: Formatters.bulanQuery(_month));
      if (!mounted) return;
      setState(() => _items = data);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat histori penyetoran.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickMonth() async {
    final picked = await pickMonth(context, _month);
    if (picked == null) return;
    setState(() => _month = picked);
    await _load();
  }

  void _openDetail(SetorSampah item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetorReceiptPage(setorId: item.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Penyetoran'),
        actions: [
          TextButton.icon(
            onPressed: _pickMonth,
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: Text(
              '${Formatters.monthNames[_month.month - 1]} ${_month.year}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      body: StateContainer(
        loading: _loading,
        error: _error,
        isEmpty: _items.isEmpty,
        emptyTitle: 'Belum Ada Penyetoran',
        emptyMessage:
            'Histori penyetoran bulan ini akan muncul setelah Anda mengajukan setor sampah.',
        onRetry: _load,
        child: RefreshIndicator(
          color: AppTheme.green,
          onRefresh: _load,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final s = _items[i];
              final style = StatusStyle.setor(s.status);
              return Card(
                child: ListTile(
                  onTap: () => _openDetail(s),
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.greenLight,
                    child: Icon(Icons.recycling, color: AppTheme.green, size: 20),
                  ),
                  title: Text(s.kodeSetor,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    '${Formatters.date(s.tanggal)} • ${Formatters.kg(s.totalBeratKg)} kg • ${Formatters.poin(s.totalPoin)} poin',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: StatusChip(label: style.$1, color: style.$2),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
