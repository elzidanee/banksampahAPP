import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sampahbank/data/models/models.dart';

import '../../core/exceptions.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/master_repositories.dart';
import '../auth/auth_pages.dart';
import 'deposit_page.dart';

class KategoriSampahPage extends StatefulWidget {
  const KategoriSampahPage({super.key});

  @override
  State<KategoriSampahPage> createState() => _KategoriSampahPageState();
}

class _KategoriSampahPageState extends State<KategoriSampahPage> {
  final _search = TextEditingController();
  List<KategoriSampah> _items = [];
  bool _loading = true;
  String? _error;

  List<KategoriSampah> get _filtered {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items
        .where((item) => item.namaKategori.toLowerCase().contains(query))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await KategoriRepository(AuthScope.of(context).api).list();
      if (mounted) setState(() => _items = items);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat kategori sampah.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('Jenis Sampah Daur Ulang')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari jenis sampah...',
              ),
            ),
          ),
          Expanded(
            child: StateContainer(
              loading: _loading,
              error: _error,
              onRetry: _load,
              isEmpty: items.isEmpty,
              emptyTitle: 'Kategori tidak ditemukan',
              emptyMessage: 'Coba gunakan kata kunci lain.',
              child: RefreshIndicator(
                color: AppTheme.green,
                onRefresh: _load,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _categoryCard(items[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(KategoriSampah item) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DepositPage()),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SafeImage(
              url: item.foto,
              size: 72,
              fallbackIcon: Icons.recycling_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.namaKategori,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  _typeBadge(item.jenis),
                  const SizedBox(height: 7),
                  Text(
                    'Rp ${NumberFormat('#,##0', 'id_ID').format(item.hargaPerKg)}/kg',
                    style: const TextStyle(
                      color: AppTheme.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${NumberFormat('#,##0.##', 'id_ID').format(item.poinPerKg)} poin/kg',
                    style: const TextStyle(
                      color: AppTheme.subtle,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.subtle),
          ],
        ),
      ),
    ),
  );
}

class CatalogPage extends KategoriSampahPage {
  const CatalogPage({super.key});
}

class KategoriSampahDetailPage extends StatelessWidget {
  final KategoriSampah category;
  const KategoriSampahDetailPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0', 'id_ID');
    final points = NumberFormat('#,##0.##', 'id_ID');
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Jenis Sampah')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SafeImage(
            url: category.foto,
            size: double.infinity,
            fallbackIcon: Icons.recycling_outlined,
            borderRadius: BorderRadius.circular(18),
          ),
          const SizedBox(height: 20),
          Text(
            category.namaKategori,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          _typeBadge(category.jenis),
          const SizedBox(height: 22),
          _detail('Harga per kg', 'Rp ${money.format(category.hargaPerKg)}'),
          _detail('Poin per kg', '${points.format(category.poinPerKg)} poin'),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Card(
    child: ListTile(
      title: Text(label, style: const TextStyle(color: AppTheme.subtle)),
      trailing: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppTheme.green,
        ),
      ),
    ),
  );
}

Widget _typeBadge(String type) {
  final color = switch (type.toLowerCase()) {
    'plastik' => AppTheme.blue,
    'kertas' => AppTheme.amber,
    'logam' => const Color(0xFFC7C7CC),
    'kaca' => const Color(0xFF64E6C1),
    _ => AppTheme.subtle,
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      type,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}
