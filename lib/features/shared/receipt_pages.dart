import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../core/exceptions.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/transaction_repositories.dart';
import '../auth/auth_pages.dart';
import '../nasabah/models/models.dart';

/// Printable digital receipt for penyetoran sampah (UKK Nasabah #8).
class SetorReceiptPage extends StatefulWidget {
  final String setorId;
  const SetorReceiptPage({super.key, required this.setorId});

  @override
  State<SetorReceiptPage> createState() => _SetorReceiptPageState();
}

class _SetorReceiptPageState extends State<SetorReceiptPage> {
  final GlobalKey _receiptKey = GlobalKey();
  SetorSampah? _data;
  bool _loading = true;
  String? _error;
  bool _exporting = false;

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
      final data = await repo.detail(widget.setorId);
      if (!mounted) return;
      setState(() => _data = data);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat nota penyetoran.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Uint8List?> _captureImageBytes() async {
    await SchedulerBinding.instance.endOfFrame;
    await SchedulerBinding.instance.endOfFrame;

    final renderObject = _receiptKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;

    if (renderObject.debugNeedsPaint) {
      await SchedulerBinding.instance.endOfFrame;
    }

    final ratio = mounted
        ? View.of(context).devicePixelRatio.clamp(2.0, 4.0)
        : 2.0;

    final image = await renderObject.toImage(pixelRatio: ratio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<Uint8List> _wrapImageAsPdf(Uint8List pngBytes) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(pngBytes);
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) =>
            pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    );
    return pdf.save();
  }

  Future<void> _saveReceiptImage(SetorSampah s, {required bool asPdf}) async {
    setState(() => _exporting = true);
    try {
      final bytes = await _captureImageBytes();
      if (bytes == null) {
        if (!mounted) return;
        showFeedback(context, 'Gagal membuat nota visual. Silakan coba kembali.');
        return;
      }

      final fileName =
          'nota_setor_${s.kodeSetor.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.${asPdf ? 'pdf' : 'png'}';

      if (asPdf) {
        final pdfBytes = await _wrapImageAsPdf(bytes);
        final dir =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final file = File('${dir.path}${Platform.pathSeparator}$fileName');
        await file.writeAsBytes(pdfBytes);
        if (!mounted) return;
        showFeedback(context, 'Dokumen PDF tersimpan di folder Unduhan (${dir.path})');
      } else {
        final location = await _saveBytesToDevice(bytes, fileName);
        if (!mounted) return;
        showFeedback(
          context,
          _supportsGallery
              ? 'Nota transaksi berhasil disimpan ke Galeri Foto.'
              : 'Nota transaksi berhasil disimpan di: $location',
        );
      }
    } on GalException catch (e) {
      if (!mounted) return;
      showFeedback(context, 'Gagal menyimpan ke galeri: ${e.type.message}');
    } on StateError catch (e) {
      if (!mounted) return;
      showFeedback(context, e.message);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _shareReceiptImage(SetorSampah s, {required bool asPdf}) async {
    setState(() => _exporting = true);
    try {
      final bytes = await _captureImageBytes();
      if (bytes == null) {
        if (!mounted) return;
        showFeedback(context, 'Gagal menyiapkan berkas nota untuk dibagikan.');
        return;
      }

      final fileName =
          'nota_setor_${s.kodeSetor.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.${asPdf ? 'pdf' : 'png'}';
      final output = asPdf ? await _wrapImageAsPdf(bytes) : bytes;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(output);

      if (_supportsNativeFileShare) {
        await Share.shareXFiles([
          XFile(
            file.path,
            mimeType: asPdf ? 'application/pdf' : 'image/png',
            name: fileName,
          ),
        ], text: 'Bukti Penyetoran Sampah Resmi - Bank Sampah Digital (${s.kodeSetor})');
      } else {
        await _revealInFileExplorer(file.path);
        if (!mounted) return;
        showFeedback(
          context,
          'Berkas telah disiapkan. Seret file nota untuk mengirimkannya.',
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _pickReceiptExport({required bool share}) async {
    final result = await showModalBottomSheet<_ReceiptExportType>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.lineStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Format Dokumen',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih format file bukti transaksi yang ingin diunduh atau dibagikan',
                style: TextStyle(fontSize: 12.5, color: AppTheme.subtle),
              ),
              const SizedBox(height: 16),
              _exportOptionTile(
                icon: Icons.image_outlined,
                title: 'Gambar Digital (.png)',
                subtitle: 'Cocok untuk disimpan di galeri atau dibagikan via chat',
                onTap: () => Navigator.pop(context, _ReceiptExportType.image),
              ),
              const SizedBox(height: 8),
              _exportOptionTile(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Dokumen Portabel (.pdf)',
                subtitle: 'Format resmi untuk arsip cetak atau dokumen laporan',
                onTap: () => Navigator.pop(context, _ReceiptExportType.pdf),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || result == null || _data == null) return;

    if (share) {
      await _shareReceiptImage(_data!, asPdf: result == _ReceiptExportType.pdf);
    } else {
      await _saveReceiptImage(_data!, asPdf: result == _ReceiptExportType.pdf);
    }
  }

  Widget _exportOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.greenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.green, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.subtle,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.subtle, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Bukti Setor Sampah'),
        actions: [
          if (_data != null)
            IconButton(
              tooltip: 'Bagikan Bukti',
              onPressed: _exporting ? null : () => _pickReceiptExport(share: true),
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),
      body: StateContainer(
        loading: _loading,
        error: _error,
        isEmpty: false,
        onRetry: _load,
        child: _data == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  RepaintBoundary(
                    key: _receiptKey,
                    child: _SetorReceiptTicket(data: _data!),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _exporting
                              ? null
                              : () => _pickReceiptExport(share: false),
                          icon: _exporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 20),
                          label: const Text(
                            'Simpan Nota',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _exporting
                              ? null
                              : () => _pickReceiptExport(share: true),
                          icon: const Icon(Icons.share_rounded, size: 20),
                          label: const Text(
                            'Bagikan Dokumen',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// Printable digital receipt for penukaran poin (UKK Nasabah #8).
class PenukaranReceiptPage extends StatefulWidget {
  final String penukaranId;
  const PenukaranReceiptPage({super.key, required this.penukaranId});

  @override
  State<PenukaranReceiptPage> createState() => _PenukaranReceiptPageState();
}

class _PenukaranReceiptPageState extends State<PenukaranReceiptPage> {
  final GlobalKey _receiptKey = GlobalKey();
  PenukaranPoin? _data;
  bool _loading = true;
  String? _error;
  bool _exporting = false;

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
      final data = await repo.note(widget.penukaranId);
      if (!mounted) return;
      setState(() => _data = data);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat nota penukaran.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Uint8List?> _captureImageBytes() async {
    await SchedulerBinding.instance.endOfFrame;
    await SchedulerBinding.instance.endOfFrame;

    final renderObject = _receiptKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;

    if (renderObject.debugNeedsPaint) {
      await SchedulerBinding.instance.endOfFrame;
    }

    final ratio = mounted
        ? View.of(context).devicePixelRatio.clamp(2.0, 4.0)
        : 2.0;

    final image = await renderObject.toImage(pixelRatio: ratio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<Uint8List> _wrapImageAsPdf(Uint8List pngBytes) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(pngBytes);
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) =>
            pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    );
    return pdf.save();
  }

  Future<void> _saveReceiptImage(PenukaranPoin p, {required bool asPdf}) async {
    setState(() => _exporting = true);
    try {
      final bytes = await _captureImageBytes();
      if (bytes == null) {
        if (!mounted) return;
        showFeedback(context, 'Gagal membuat nota visual. Silakan coba kembali.');
        return;
      }

      final fileName =
          'nota_penukaran_${p.kodePenukaran.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.${asPdf ? 'pdf' : 'png'}';

      if (asPdf) {
        final pdfBytes = await _wrapImageAsPdf(bytes);
        final dir =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final file = File('${dir.path}${Platform.pathSeparator}$fileName');
        await file.writeAsBytes(pdfBytes);
        if (!mounted) return;
        showFeedback(context, 'Dokumen PDF tersimpan di folder Unduhan (${dir.path})');
      } else {
        final location = await _saveBytesToDevice(bytes, fileName);
        if (!mounted) return;
        showFeedback(
          context,
          _supportsGallery
              ? 'Nota penukaran berhasil disimpan ke Galeri Foto.'
              : 'Nota penukaran berhasil disimpan di: $location',
        );
      }
    } on GalException catch (e) {
      if (!mounted) return;
      showFeedback(context, 'Gagal menyimpan ke galeri: ${e.type.message}');
    } on StateError catch (e) {
      if (!mounted) return;
      showFeedback(context, e.message);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _shareReceiptImage(
    PenukaranPoin p, {
    required bool asPdf,
  }) async {
    setState(() => _exporting = true);
    try {
      final bytes = await _captureImageBytes();
      if (bytes == null) {
        if (!mounted) return;
        showFeedback(context, 'Gagal menyiapkan berkas nota untuk dibagikan.');
        return;
      }

      final fileName =
          'nota_penukaran_${p.kodePenukaran.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.${asPdf ? 'pdf' : 'png'}';
      final output = asPdf ? await _wrapImageAsPdf(bytes) : bytes;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(output);

      if (_supportsNativeFileShare) {
        await Share.shareXFiles([
          XFile(
            file.path,
            mimeType: asPdf ? 'application/pdf' : 'image/png',
            name: fileName,
          ),
        ], text: 'Bukti Penukaran Poin Resmi - Bank Sampah Digital (${p.kodePenukaran})');
      } else {
        await _revealInFileExplorer(file.path);
        if (!mounted) return;
        showFeedback(
          context,
          'Berkas telah disiapkan. Seret file nota untuk mengirimkannya.',
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _pickReceiptExport({required bool share}) async {
    final result = await showModalBottomSheet<_ReceiptExportType>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.lineStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Format Dokumen',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih format file bukti transaksi yang ingin diunduh atau dibagikan',
                style: TextStyle(fontSize: 12.5, color: AppTheme.subtle),
              ),
              const SizedBox(height: 16),
              _exportOptionTile(
                icon: Icons.image_outlined,
                title: 'Gambar Digital (.png)',
                subtitle: 'Cocok untuk disimpan di galeri atau dibagikan via chat',
                onTap: () => Navigator.pop(context, _ReceiptExportType.image),
              ),
              const SizedBox(height: 8),
              _exportOptionTile(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Dokumen Portabel (.pdf)',
                subtitle: 'Format resmi untuk arsip cetak atau dokumen laporan',
                onTap: () => Navigator.pop(context, _ReceiptExportType.pdf),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || result == null || _data == null) return;

    if (share) {
      await _shareReceiptImage(_data!, asPdf: result == _ReceiptExportType.pdf);
    } else {
      await _saveReceiptImage(_data!, asPdf: result == _ReceiptExportType.pdf);
    }
  }

  Widget _exportOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.blueLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.blue, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.subtle,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.subtle, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Bukti Penukaran Poin'),
        actions: [
          if (_data != null)
            IconButton(
              tooltip: 'Bagikan Bukti',
              onPressed: _exporting ? null : () => _pickReceiptExport(share: true),
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),
      body: StateContainer(
        loading: _loading,
        error: _error,
        isEmpty: false,
        onRetry: _load,
        child: _data == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  RepaintBoundary(
                    key: _receiptKey,
                    child: _PenukaranReceiptTicket(data: _data!),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _exporting
                              ? null
                              : () => _pickReceiptExport(share: false),
                          icon: _exporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 20),
                          label: const Text(
                            'Simpan Nota',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _exporting
                              ? null
                              : () => _pickReceiptExport(share: true),
                          icon: const Icon(Icons.share_rounded, size: 20),
                          label: const Text(
                            'Bagikan Dokumen',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Redesigned Digital Receipt Components (Authentic Ticket Layout)
// ---------------------------------------------------------------------------

class _SetorReceiptTicket extends StatelessWidget {
  final SetorSampah data;
  const _SetorReceiptTicket({required this.data});

  @override
  Widget build(BuildContext context) {
    final statusInfo = StatusStyle.setor(data.status);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.line, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Institution Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo2.png',
                      height: 38,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.recycling_rounded,
                        color: AppTheme.green,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'BANK SAMPAH DIGITAL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: AppTheme.ink,
                          ),
                        ),
                        Text(
                          'Unit Pengelolaan & Daur Ulang Mandiri',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.subtle,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.greenLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.greenBorder),
                  ),
                  child: const Text(
                    'LEMBAR BUKTI PENYETORAN SAMPAH',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppTheme.greenDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Transaction Hero Value & Status
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.line),
            ),
            child: Column(
              children: [
                const Text(
                  'TOTAL PEROLEHAN INSENTIF',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: AppTheme.subtle,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '+${Formatters.poin(data.totalPoin)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.green,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'POIN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.greenDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StatusChip(label: statusInfo.$1, color: statusInfo.$2),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Perforated Divider with Cutout Notches
          const _PerforatedCutoutDivider(),

          // 4. Primary Transaction Meta
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _receiptRow(
                  label: 'No. Referensi',
                  value: data.kodeSetor,
                  isBold: true,
                  isCopyable: true,
                ),
                _receiptRow(
                  label: 'Waktu Transaksi',
                  value: Formatters.dateTime(data.tanggal),
                ),
                _receiptRow(
                  label: 'Nama Nasabah',
                  value: data.namaNasabah ?? 'Nasabah Terdaftar',
                  isBold: true,
                ),
                if (data.telpNasabah != null && data.telpNasabah!.isNotEmpty)
                  _receiptRow(
                    label: 'No. Telepon',
                    value: data.telpNasabah!,
                  ),
                _receiptRow(
                  label: 'Akumulasi Netto',
                  value: '${Formatters.kg(data.totalBeratKg)} kg',
                  isBold: true,
                  valueColor: AppTheme.ink,
                ),
              ],
            ),
          ),

          // 5. Itemized Breakdown Table
          if (data.items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'KOMODITAS MATERIAL',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.subtle,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'BERAT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.subtle,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'SUBTOTAL',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.subtle,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final item in data.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              item.namaKategori ?? 'Kategori Sampah',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.ink,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${Formatters.kg(item.beratKg)} kg',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.inkMedium,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '+${Formatters.poin(item.subtotalPoin)} P',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppTheme.line),
                ],
              ),
            ),
          ],

          // 6. Notes (if any)
          if ((data.catatan != null && data.catatan!.isNotEmpty) ||
              (data.catatanAdmin != null && data.catatanAdmin!.isNotEmpty)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.catatan != null && data.catatan!.isNotEmpty) ...[
                      const Text(
                        'Catatan Nasabah:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.subtle,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.catatan!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.inkMedium,
                        ),
                      ),
                    ],
                    if (data.catatanAdmin != null &&
                        data.catatanAdmin!.isNotEmpty) ...[
                      if (data.catatan != null && data.catatan!.isNotEmpty)
                        const SizedBox(height: 8),
                      const Text(
                        'Verifikasi Petugas:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.greenDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.catatanAdmin!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.ink,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          // 7. Security Barcode & Legal Notice Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                _SimulatedBarcode(code: data.kodeSetor),
                const SizedBox(height: 8),
                Text(
                  'AUTH-SECURE // ${data.kodeSetor}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.subtle,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Dokumen digital ini merupakan lembar tanda terima transaksi elektronik yang sah dan terenkripsi. Diterbitkan secara otomatis oleh Sistem Bank Sampah Digital tanpa memerlukan tanda tangan basah.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.45,
                    color: AppTheme.subtle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PenukaranReceiptTicket extends StatelessWidget {
  final PenukaranPoin data;
  const _PenukaranReceiptTicket({required this.data});

  @override
  Widget build(BuildContext context) {
    final statusInfo = StatusStyle.penukaran(data.status);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.line, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Institution Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo2.png',
                      height: 38,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.card_giftcard_rounded,
                        color: AppTheme.green,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'BANK SAMPAH DIGITAL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: AppTheme.ink,
                          ),
                        ),
                        Text(
                          'Program Apresiasi & Penukaran Insentif',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.subtle,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.blueLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.blue.withValues(alpha: .25),
                    ),
                  ),
                  child: const Text(
                    'LEMBAR BUKTI PENUKARAN REWARD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppTheme.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Transaction Hero Value & Status
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.line),
            ),
            child: Column(
              children: [
                const Text(
                  'NOMINAL POIN DIDIBET',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: AppTheme.subtle,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '-${Formatters.poin(data.poinTerpakai)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'POIN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.inkMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StatusChip(label: statusInfo.$1, color: statusInfo.$2),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Perforated Divider with Cutout Notches
          const _PerforatedCutoutDivider(),

          // 4. Primary Transaction Meta
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _receiptRow(
                  label: 'No. Dokumen',
                  value: data.kodePenukaran,
                  isBold: true,
                  isCopyable: true,
                ),
                _receiptRow(
                  label: 'Waktu Transaksi',
                  value: Formatters.dateTime(data.tanggal),
                ),
                _receiptRow(
                  label: 'Nama Nasabah',
                  value: data.namaNasabah ?? 'Nasabah Terdaftar',
                  isBold: true,
                ),
                if (data.telpNasabah != null && data.telpNasabah!.isNotEmpty)
                  _receiptRow(
                    label: 'No. Telepon',
                    value: data.telpNasabah!,
                  ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppTheme.line),
                const SizedBox(height: 10),
                _receiptRow(
                  label: 'Item Reward',
                  value: data.namaHadiah ?? 'Hadiah Fisik / Voucher',
                  isBold: true,
                  valueColor: AppTheme.greenDark,
                ),
                _receiptRow(
                  label: 'Poin Didebet',
                  value: '-${Formatters.poin(data.poinTerpakai)} poin',
                  isBold: true,
                ),
                if (data.sisaSaldoPoin != null)
                  _receiptRow(
                    label: 'Sisa Saldo Poin',
                    value: '${Formatters.poin(data.sisaSaldoPoin)} poin',
                    isBold: true,
                    valueColor: AppTheme.ink,
                  ),
              ],
            ),
          ),

          // 5. Security Barcode & Legal Notice Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                _SimulatedBarcode(code: data.kodePenukaran),
                const SizedBox(height: 8),
                Text(
                  'AUTH-REWARD // ${data.kodePenukaran}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.subtle,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tunjukkan lembar bukti penukaran digital ini kepada petugas di Unit Bank Sampah untuk pengambilan hadiah fisik atau aktivasi reward yang dipilih.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.45,
                    color: AppTheme.subtle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers & Visual Ornaments
// ---------------------------------------------------------------------------

Widget _receiptRow({
  required String label,
  required String value,
  bool isBold = false,
  bool isCopyable = false,
  Color? valueColor,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 124,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.subtle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12.5,
              color: valueColor ?? AppTheme.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

/// A realistic ticket divider with circular bite/notches on both edges and a dashed line.
class _PerforatedCutoutDivider extends StatelessWidget {
  const _PerforatedCutoutDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 20,
            right: 20,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const dashWidth = 5.0;
                const dashSpace = 4.0;
                final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(count, (_) {
                    return Container(
                      width: dashWidth,
                      height: 1.2,
                      color: AppTheme.lineStrong,
                    );
                  }),
                );
              },
            ),
          ),
          Positioned(
            left: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.bg,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.line, width: 1.2),
              ),
            ),
          ),
          Positioned(
            right: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.bg,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.line, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simulated modern retail barcode graphic.
class _SimulatedBarcode extends StatelessWidget {
  final String code;
  const _SimulatedBarcode({required this.code});

  @override
  Widget build(BuildContext context) {
    final bars = <int>[];
    for (var i = 0; i < 46; i++) {
      final charCode = code.codeUnitAt(i % code.length);
      bars.add((charCode + i * 3) % 4 + 1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < bars.length; i++) ...[
            Container(
              width: bars[i] * 1.3,
              height: 36,
              color: i % 2 == 0 ? AppTheme.ink : Colors.transparent,
            ),
            const SizedBox(width: 1.5),
          ],
        ],
      ),
    );
  }
}

enum _ReceiptExportType { image, pdf }

bool get _supportsGallery {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}

bool get _supportsNativeFileShare {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}

Future<void> _revealInFileExplorer(String filePath) async {
  if (Platform.isWindows) {
    await Process.run('explorer.exe', ['/select,', filePath]);
  } else if (Platform.isLinux) {
    final dir = File(filePath).parent.path;
    await Process.run('xdg-open', [dir]);
  }
}

Future<String> _saveBytesToDevice(Uint8List bytes, String fileName) async {
  if (_supportsGallery) {
    final hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      final granted = await Gal.requestAccess();
      if (!granted) {
        throw StateError('Izin akses galeri perangkat ditolak.');
      }
    }
    await Gal.putImageBytes(bytes, name: fileName);
    return 'galeri';
  }

  final dir =
      await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes);
  return dir.path;
}
