import 'package:flutter/material.dart';

import '../../core/exceptions.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/transaction_repositories.dart';
import '../auth/auth_pages.dart';
import 'models/models.dart';

/// Executive Recap & Operational Analytics Screen (UKK Admin).
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
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat data rekapitulasi operasional.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _prevMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month - 1);
    });
    _load();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_month.year, _month.month + 1);
    if (next.isAfter(DateTime(now.year, now.month + 1))) return;
    setState(() {
      _month = next;
    });
    _load();
  }

  void _resetToCurrentMonth() {
    setState(() {
      _month = DateTime(DateTime.now().year, DateTime.now().month);
    });
    _load();
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.green,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        children: [
          // 1. Interactive Period Switcher Bar
          _buildPeriodNavigatorBar(),
          const SizedBox(height: 14),

          // 2. Main Data Content
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
                      // A. Hero Aggregate Physical Volume & Monetary Valuation
                      _buildHeroNeracaCard(_data!),
                      const SizedBox(height: 14),

                      // B. Points Circulation Velocity (Inflow vs Outflow)
                      _buildCirculationDualCards(_data!),
                      const SizedBox(height: 14),

                      // C. Points Liquidity & Redemption Ratio Meter
                      _buildPointsLiquidityMeter(_data!),
                      const SizedBox(height: 20),

                      // D. Commodity Composition & Structural Breakdown
                      _buildCommodityCompositionSection(_data!),
                      const SizedBox(height: 20),

                      // E. Audit & Operational Integrity Statement
                      _buildAuditStatementCard(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Period Selection Navigator
  // -------------------------------------------------------------------------

  Widget _buildPeriodNavigatorBar() {
    final monthName = Formatters.monthNames[_month.month - 1];
    final year = _month.year;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Bulan Sebelumnya',
            onPressed: _loading ? null : _prevMonth,
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final picked = await pickMonth(context, _month);
                if (picked == null || !mounted) return;
                setState(() => _month = picked);
                _load();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 16,
                      color: AppTheme.green,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$monthName $year',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 18,
                      color: AppTheme.subtle,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Bulan Berikutnya',
            onPressed: _loading ? null : _nextMonth,
            icon: const Icon(Icons.chevron_right_rounded, size: 22),
            visualDensity: VisualDensity.compact,
          ),
          if (!_isCurrentMonth) ...[
            Container(width: 1, height: 18, color: AppTheme.line),
            const SizedBox(width: 2),
            IconButton(
              tooltip: 'Kembali ke Bulan Ini',
              onPressed: _loading ? null : _resetToCurrentMonth,
              icon: const Icon(Icons.today_rounded, size: 18, color: AppTheme.green),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Hero Neraca Tonase Card
  // -------------------------------------------------------------------------

  Widget _buildHeroNeracaCard(RekapBulanan data) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: .18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top tag row with Expanded on text to eliminate right overflow
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'VOLUME FISIK TERTANGANI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4ADE80).withValues(alpha: .3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.circle, size: 6, color: Color(0xFF4ADE80)),
                      SizedBox(width: 5),
                      Text(
                        'Terkonsolidasi',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4ADE80),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Large Hero Metric (Tonase) with Flexible guards
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    Formatters.kg(data.totalKg),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'KG',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '≈ ${data.totalTon} Ton Metrik',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE2E8F0),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            const Divider(height: 1, color: Color(0xFF334155)),
            const SizedBox(height: 14),

            // Financial Projections Grid
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Proyeksi Valuasi Finansial',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        Formatters.rupiah(data.totalEstimasiPembayaran),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4ADE80),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Nilai komoditas sebelum olah',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 38, color: const Color(0xFF334155)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Tingkat Diversi Sampah',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '100% Terkelola',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Bebas penimbunan residu TPA',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Points Circulation Velocity (Inflow vs Outflow)
  // -------------------------------------------------------------------------

  Widget _buildCirculationDualCards(RekapBulanan data) {
    return Row(
      children: [
        // Card 1: Penerbitan Poin (Inflow)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.greenBorder),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.greenLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.south_west_rounded,
                        color: AppTheme.green,
                        size: 16,
                      ),
                    ),
                    const Text(
                      'INFLOW',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppTheme.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Insentif Diterbitkan',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.subtle,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '+${Formatters.poin(data.totalPoinDiterbitkan)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.greenDark,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Kredit masuk ke nasabah',
                  style: TextStyle(fontSize: 10, color: AppTheme.subtle),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Card 2: Penebusan Hadiah (Outflow)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.amber.withValues(alpha: .25),
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.amberLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.north_east_rounded,
                        color: AppTheme.amber,
                        size: 16,
                      ),
                    ),
                    const Text(
                      'OUTFLOW',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppTheme.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Realisasi Penukaran',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.subtle,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '-${Formatters.poin(data.totalPoinTerpakai)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${data.totalTransaksiPenukaran} kali klaim reward',
                  style: const TextStyle(fontSize: 10, color: AppTheme.subtle),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Points Liquidity Meter
  // -------------------------------------------------------------------------

  Widget _buildPointsLiquidityMeter(RekapBulanan data) {
    final diterbitkan = data.totalPoinDiterbitkan;
    final terpakai = data.totalPoinTerpakai;
    final rasio = diterbitkan > 0
        ? (terpakai / diterbitkan * 100).clamp(0.0, 100.0)
        : 0.0;
    final sisaPoinBeredar = (diterbitkan - terpakai).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Expanded Column to prevent horizontal overflow
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Rasio Likuiditas & Konversi Reward',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Persentase poin yang ditukarkan nasabah dari total penerbitan',
                      style: TextStyle(fontSize: 11, color: AppTheme.subtle),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.line),
                ),
                child: Text(
                  '${rasio.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom visual progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: AppTheme.greenBorder),
                  FractionallySizedBox(
                    widthFactor: (rasio / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Legend wrapped with Wrap to ensure no overflow on small screens
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _legendDot(
                color: AppTheme.amber,
                label: 'Ditebus: ${Formatters.poin(terpakai)} Poin',
              ),
              _legendDot(
                color: AppTheme.green,
                label: 'Saldo Beredar: ${Formatters.poin(sisaPoinBeredar)} Poin',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.inkMedium,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Commodity Composition Section
  // -------------------------------------------------------------------------

  Widget _buildCommodityCompositionSection(RekapBulanan data) {
    final entries = data.breakdownJenis.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Expanded Column to prevent horizontal overflow
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Distribusi Komposisi Material',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: AppTheme.ink,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Performa penyerapan tonase, valuasi kas, dan alokasi poin per komoditas',
                    style: TextStyle(fontSize: 11, color: AppTheme.subtle),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.line),
              ),
              child: Text(
                '${entries.length} Jenis',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.inkMedium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.line),
            ),
            child: const Center(
              child: Text(
                'Belum ada data penyerapan sampah pada periode ini.',
                style: TextStyle(fontSize: 12.5, color: AppTheme.subtle),
              ),
            ),
          )
        else
          for (final entry in entries) ...[
            _buildCommodityItemCard(
              jenis: entry.key,
              data: entry.value,
              totalKg: data.totalKg,
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _buildCommodityItemCard({
    required String jenis,
    required RekapJenis data,
    required double totalKg,
  }) {
    final share = totalKg > 0 ? (data.tonaseKg / totalKg * 100) : 0.0;
    final meta = _getCommodityMeta(jenis);
    final isEmpty = data.tonaseKg <= 0;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEmpty ? AppTheme.line : meta.accentColor.withValues(alpha: .25),
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Opacity(
        opacity: isEmpty ? 0.5 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon, Title, and Proportion Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: meta.accentColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(meta.icon, color: meta.accentColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleCase(jenis),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        meta.description,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.subtle,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: meta.accentColor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '${share.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: meta.accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Share Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 5,
                child: LinearProgressIndicator(
                  value: (share / 100).clamp(0.0, 1.0),
                  backgroundColor: AppTheme.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(meta.accentColor),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3-Metric Pillar Row
            Row(
              children: [
                _metricPillar(
                  label: 'Volume Netto',
                  value: '${Formatters.kg(data.tonaseKg)} kg',
                  valueColor: AppTheme.ink,
                ),
                _metricPillar(
                  label: 'Valuasi Kas',
                  value: Formatters.rupiah(data.rupiah),
                  valueColor: AppTheme.greenDark,
                ),
                _metricPillar(
                  label: 'Alokasi Poin',
                  value: '${Formatters.poin(data.poin)} P',
                  valueColor: meta.accentColor,
                  isRightAligned: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricPillar({
    required String label,
    required String value,
    required Color valueColor,
    bool isRightAligned = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment:
            isRightAligned ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.subtle,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Audit & Integrity Statement Card
  // -------------------------------------------------------------------------

  Widget _buildAuditStatementCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: AppTheme.green,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Integritas Data & Validasi Dokumen',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Seluruh agregat tonase, sirkulasi poin, dan estimasi valuasi pada laporan ini dikompilasi secara real-time dari riwayat transaksi yang terverifikasi di pangkalan data Bank Sampah Digital.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: AppTheme.subtle,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sinkronisasi Sistem: ${Formatters.dateTime(DateTime.now().toIso8601String())}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.inkMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Helpers & Commodity Metadata
  // -------------------------------------------------------------------------

  _CommodityMeta _getCommodityMeta(String jenis) {
    return switch (jenis.toLowerCase()) {
      'plastik' => const _CommodityMeta(
          icon: Icons.local_drink_outlined,
          accentColor: Color(0xFF0284C7),
          description: 'Botol PET, kresek, gelas, & wadah polimer',
        ),
      'kertas' => const _CommodityMeta(
          icon: Icons.inventory_2_outlined,
          accentColor: Color(0xFFD97706),
          description: 'Kardus, duplex, koran, & kertas arsip',
        ),
      'logam' => const _CommodityMeta(
          icon: Icons.hardware_outlined,
          accentColor: Color(0xFF6366F1),
          description: 'Besi, aluminium kaleng, & tembaga',
        ),
      'kaca' => const _CommodityMeta(
          icon: Icons.wine_bar_outlined,
          accentColor: Color(0xFF0D9488),
          description: 'Botol sirup, kecap, & toples beling',
        ),
      'minyak' || 'jelantah' => const _CommodityMeta(
          icon: Icons.opacity_outlined,
          accentColor: Color(0xFFCA8A04),
          description: 'Minyak jelantah rumah tangga',
        ),
      _ => const _CommodityMeta(
          icon: Icons.recycling_outlined,
          accentColor: Color(0xFF8B5CF6),
          description: 'Komoditas anorganik & lainnya',
        ),
    };
  }

  String _titleCase(String value) => value.isEmpty
      ? value
      : '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}

class _CommodityMeta {
  final IconData icon;
  final Color accentColor;
  final String description;

  const _CommodityMeta({
    required this.icon,
    required this.accentColor,
    required this.description,
  });
}
