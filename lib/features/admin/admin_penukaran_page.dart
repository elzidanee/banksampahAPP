import 'package:flutter/material.dart';

import '../../core/exceptions.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/transaction_repositories.dart';
import '../auth/auth_pages.dart';
import '../shared/receipt_pages.dart';
import 'models/models.dart';

class AdminPenukaranPage extends StatefulWidget {
  const AdminPenukaranPage({super.key});

  @override
  State<AdminPenukaranPage> createState() => _AdminPenukaranPageState();
}

class _AdminPenukaranPageState extends State<AdminPenukaranPage> {
  List<PenukaranPoin> _items = [];
  bool _loading = true;
  String? _error;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _statusFilter = 'semua';

  List<PenukaranPoin> get _filteredItems => _statusFilter == 'semua'
      ? _items
      : _items.where((item) => item.status == _statusFilter).toList();

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
      final repo = RedemptionRepository(AuthScope.of(context).api);
      final data = await repo.adminList(bulan: Formatters.bulanQuery(_month));
      if (!mounted) return;
      setState(() => _items = data);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(PenukaranPoin p, String status) async {
    try {
      await RedemptionRepository(
        AuthScope.of(context).api,
      ).updateStatus(p.id, status);
      if (!mounted) return;
      showFeedback(context, 'Status penukaran diperbarui.');
      _load();
    } on AppException catch (e) {
      if (mounted) showFeedback(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                  children: [
                    _statusChip('semua', 'Semua'),
                    _statusChip('diproses', 'Diproses'),
                    _statusChip('selesai', 'Selesai'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: TextButton.icon(
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
              ),
            ],
          ),
        ),
        Expanded(
          child: StateContainer(
            loading: _loading,
            error: _error,
            isEmpty: _filteredItems.isEmpty,
            onRetry: _load,
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.green,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _filteredItems.length,
                itemBuilder: (context, i) {
                  final p = _filteredItems[i];
                  final style = StatusStyle.penukaran(p.status);
                  return Card(
                    child: ListTile(
                      title: Text(
                        p.namaHadiah ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${p.namaNasabah ?? '-'} • ${Formatters.date(p.tanggal)} • -${Formatters.poin(p.poinTerpakai)} poin',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'nota') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PenukaranReceiptPage(penukaranId: p.id),
                              ),
                            );
                          } else {
                            _updateStatus(p, v);
                          }
                        },
                        itemBuilder: (_) => [
                          if (p.status == 'diproses')
                            const PopupMenuItem(
                              value: 'selesai',
                              child: Text('Tandai Selesai'),
                            ),
                          const PopupMenuItem(
                            value: 'nota',
                            child: Text('Lihat Nota'),
                          ),
                        ],
                      ),
                      leading: StatusChip(label: style.$1, color: style.$2),
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

  Widget _statusChip(String value, String label) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _statusFilter = value),
        selectedColor: AppTheme.greenLight,
        backgroundColor: AppTheme.surface,
        side: BorderSide(color: selected ? AppTheme.green : AppTheme.line),
        labelStyle: TextStyle(
          color: selected ? AppTheme.green : AppTheme.subtle,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
        showCheckmark: false,
      ),
    );
  }
}
