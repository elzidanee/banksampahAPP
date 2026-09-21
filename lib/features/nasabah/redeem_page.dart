import 'package:flutter/material.dart';

import '../../core/exceptions.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/master_repositories.dart';
import '../../data/transaction_repositories.dart';
import '../auth/auth_pages.dart';
import '../shared/receipt_pages.dart';
import 'models/models.dart';

/// Screen 6 — Tukar poin: katalog hadiah + histori penukaran.
class RedeemPage extends StatefulWidget {
  final int initialTab;

  const RedeemPage({super.key, this.initialTab = 0});

  @override
  State<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab.clamp(0, 1),
  );

  List<Hadiah> _catalog = [];
  List<PenukaranPoin> _history = [];
  bool _loadingCatalog = true;
  bool _loadingHistory = true;
  String? _catalogError;
  String? _historyError;
  bool _exchanging = false;
  DateTime _historyMonth = DateTime(DateTime.now().year, DateTime.now().month);
  double? _currentPoints;
  bool _loadingPoints = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCatalog();
      _loadHistory();
      _loadCurrentPoints();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loadingCatalog = true;
      _catalogError = null;
    });
    try {
      final repo = HadiahRepository(AuthScope.of(context).api);
      final data = await repo.list();
      if (!mounted) return;
      setState(() => _catalog = data);
    } on AppException catch (e) {
      if (mounted) setState(() => _catalogError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _catalogError = 'Gagal memuat katalog hadiah.');
      }
    } finally {
      if (mounted) setState(() => _loadingCatalog = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final repo = RedemptionRepository(AuthScope.of(context).api);
      final data = await repo.mine();
      if (!mounted) return;
      setState(() => _history = data);
    } on AppException catch (e) {
      if (mounted) setState(() => _historyError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _historyError = 'Gagal memuat histori penukaran.');
      }
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _loadCurrentPoints() async {
    if (mounted) setState(() => _loadingPoints = true);
    try {
      final dashboard = await DashboardRepository(
        AuthScope.of(context).api,
      ).nasabahSummary();
      if (mounted) {
        setState(() => _currentPoints = dashboard.saldoPoin);
      }
    } on AppException {
      if (mounted) setState(() => _currentPoints = null);
    } catch (_) {
      if (mounted) setState(() => _currentPoints = null);
    } finally {
      if (mounted) setState(() => _loadingPoints = false);
    }
  }

  Future<void> _pickHistoryMonth() async {
    final picked = await pickMonth(context, _historyMonth);
    if (picked == null) return;
    setState(() => _historyMonth = picked);
  }

  List<PenukaranPoin> get _filteredHistory => _history.where((item) {
    final date = DateTime.tryParse(item.tanggal);
    return date != null &&
        date.year == _historyMonth.year &&
        date.month == _historyMonth.month;
  }).toList();

  Widget _pointsBalanceCard() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Poin Saat Ini',
              style: TextStyle(color: AppTheme.subtle, fontSize: 13),
            ),
            const SizedBox(height: 4),
            _loadingPoints
                ? const SizedBox(
                    height: 30,
                    width: 30,
                    child: CircularProgressIndicator(color: AppTheme.green),
                  )
                : Text(
                    _currentPoints == null
                        ? '-'
                        : '${Formatters.poin(_currentPoints!)} Poin',
                    style: const TextStyle(
                      color: AppTheme.green,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmExchange(Hadiah h) async {
    final scope = AuthScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tukar Poin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Tukar ${Formatters.poin(h.poinDibutuhkan)} poin dengan "${h.namaHadiah}"?',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70, width: 2),
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Tukar'),
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

    setState(() => _exchanging = true);
    try {
      final repo = RedemptionRepository(scope.api);
      final result = await repo.exchange(h.id);
      if (!mounted) return;
      showFeedback(
        context,
        'Penukaran ${result.kodePenukaran} berhasil diajukan.',
      );
      if (result.sisaSaldoPoin != null) {
        if (mounted) setState(() => _currentPoints = result.sisaSaldoPoin);
      }
      await _loadCurrentPoints();
      if (!mounted) return;
      await _loadHistory();
      _tabs.animateTo(1);
    } on AppException catch (e) {
      if (mounted) showFeedback(context, e.message, error: true);
    } catch (_) {
      if (mounted) {
        showFeedback(context, 'Penukaran gagal. Coba lagi.', error: true);
      }
    } finally {
      if (mounted) setState(() => _exchanging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tukar Poin'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.green,
          unselectedLabelColor: AppTheme.subtle,
          indicatorColor: AppTheme.green,
          tabs: const [
            Tab(text: 'Katalog Hadiah'),
            Tab(text: 'Histori'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_catalogTab(), _historyTab()],
      ),
    );
  }

  Widget _catalogTab() {
    return StateContainer(
      loading: _loadingCatalog,
      error: _catalogError,
      isEmpty: _catalog.isEmpty,
      emptyTitle: 'Katalog Kosong',
      emptyMessage: 'Belum ada hadiah yang tersedia untuk ditukar.',
      onRetry: _loadCatalog,
      child: RefreshIndicator(
        color: AppTheme.green,
        onRefresh: _loadCatalog,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _catalog.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) return _pointsBalanceCard();
            final h = _catalog[i - 1];
            final outOfStock = h.stok <= 0;
            return Card(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final action = _exchanging
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : ElevatedButton(
                          onPressed: outOfStock
                              ? null
                              : () => _confirmExchange(h),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(72, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text(
                            'Tukar',
                            style: TextStyle(fontSize: 12),
                          ),
                        );

                  final details = Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.namaHadiah,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${Formatters.poin(h.poinDibutuhkan)} poin • Stok ${h.stok}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );

                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: constraints.maxWidth < 340
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SafeImage(
                                    url: h.foto,
                                    fallbackIcon: Icons.card_giftcard,
                                  ),
                                  const SizedBox(width: 12),
                                  details,
                                ],
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: action,
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SafeImage(
                                url: h.foto,
                                fallbackIcon: Icons.card_giftcard,
                              ),
                              const SizedBox(width: 12),
                              details,
                              const SizedBox(width: 8),
                              action,
                            ],
                          ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _historyTab() {
    final items = _filteredHistory;
    return StateContainer(
      loading: _loadingHistory,
      error: _historyError,
      isEmpty: items.isEmpty,
      emptyTitle: 'Belum Ada Penukaran',
      emptyMessage: 'Tidak ada penukaran pada bulan yang dipilih.',
      onRetry: _loadHistory,
      child: RefreshIndicator(
        color: AppTheme.green,
        onRefresh: _loadHistory,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length + 2,
          itemBuilder: (context, i) {
            if (i == 0) return _pointsBalanceCard();
            if (i == 1) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _pickHistoryMonth,
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: Text(
                      '${Formatters.monthNames[_historyMonth.month - 1]} ${_historyMonth.year}',
                    ),
                  ),
                ),
              );
            }
            final p = items[i - 2];
            final style = StatusStyle.penukaran(p.status);
            return Card(
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PenukaranReceiptPage(penukaranId: p.id),
                  ),
                ),
                leading: SafeImage(
                  url: p.fotoHadiah,
                  fallbackIcon: Icons.redeem_outlined,
                ),
                title: Text(
                  p.namaHadiah ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${Formatters.date(p.tanggal)} • -${Formatters.poin(p.poinTerpakai)} poin',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: StatusChip(label: style.$1, color: style.$2),
              ),
            );
          },
        ),
      ),
    );
  }
}
