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

/// Printable nota / struk for penyetoran sampah (UKK Nasabah #8).
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

  /// Waits for the widget tree to be fully laid out and painted before
  /// capturing, then converts the [RepaintBoundary] into PNG bytes.
  ///
  /// Calling `toImage()` immediately after `setState`/navigation can race
  /// the first paint, which produces a blank or stale bitmap. Waiting for
  /// two end-of-frame callbacks guarantees the boundary has a valid layer.
  Future<Uint8List?> _captureImageBytes() async {
    // Let any pending frame (e.g. right after navigation/setState) finish.
    await SchedulerBinding.instance.endOfFrame;
    await SchedulerBinding.instance.endOfFrame;

    final renderObject = _receiptKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;

    // If a frame is still scheduled, wait once more before reading pixels.
    if (renderObject.debugNeedsPaint) {
      await SchedulerBinding.instance.endOfFrame;
    }

    final image = await renderObject.toImage(
      pixelRatio: ui.window.devicePixelRatio.clamp(2.0, 4.0),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  /// Wraps the captured PNG into a single, properly sized PDF page
  /// (instead of stretching the image across a bare, marginless page).
  Future<Uint8List> _wrapImageAsPdf(Uint8List pngBytes) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(pngBytes);
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
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
        showFeedback(context, 'Gagal membuat nota visual. Coba lagi.');
        return;
      }

      final fileName =
          'nota_setor_${DateTime.now().millisecondsSinceEpoch}.${asPdf ? 'pdf' : 'png'}';

      if (asPdf) {
        final pdfBytes = await _wrapImageAsPdf(bytes);
        final dir =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final file = File('${dir.path}${Platform.pathSeparator}$fileName');
        await file.writeAsBytes(pdfBytes);
        if (!mounted) return;
        showFeedback(context, 'PDF nota tersimpan di ${dir.path}');
      } else {
        final location = await _saveBytesToDevice(bytes, fileName);
        if (!mounted) return;
        showFeedback(
          context,
          _supportsGallery
              ? 'Gambar nota tersimpan di galeri.'
              : 'Gambar nota tersimpan di $location',
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
        showFeedback(context, 'Gagal menyiapkan nota untuk dibagikan.');
        return;
      }

      final fileName =
          'nota_setor_share_${DateTime.now().millisecondsSinceEpoch}.${asPdf ? 'pdf' : 'png'}';
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
        ], text: 'Nota penyetoran sampah');
      } else {
        // Windows/Linux: WhatsApp Desktop and most desktop apps don't
        // register for the OS share contract, so a native share here
        // would silently drop the attachment. Reveal the file in the
        // explorer instead so the user can drag it in manually.
        await _revealInFileExplorer(file.path);
        if (!mounted) return;
        showFeedback(
          context,
          'File disiapkan di folder. Seret file itu ke WhatsApp Desktop untuk mengirimnya.',
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _pickReceiptExport({required bool share}) async {
    final result = await showModalBottomSheet<_ReceiptExportType>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih format nota',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Gambar (.png)'),
                onTap: () => Navigator.pop(context, _ReceiptExportType.image),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('PDF'),
                onTap: () => Navigator.pop(context, _ReceiptExportType.pdf),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || result == null) return;

    if (share) {
      await _shareReceiptImage(_data!, asPdf: result == _ReceiptExportType.pdf);
    } else {
      await _saveReceiptImage(_data!, asPdf: result == _ReceiptExportType.pdf);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nota Penyetoran')),
      body: StateContainer(
        loading: _loading,
        error: _error,
        isEmpty: false,
        onRetry: _load,
        child: _data == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  RepaintBoundary(
                    key: _receiptKey,
                    child: _ReceiptCard(
                      title: 'BANK SAMPAH',
                      subtitle: 'Bukti Penyetoran Sampah',
                      children: [
                        _row('Kode Transaksi', _data!.kodeSetor),
                        _row('Tanggal', Formatters.dateTime(_data!.tanggal)),
                        _row('Status', StatusStyle.setor(_data!.status).$1),
                        if (_data!.namaNasabah != null)
                          _row('Nasabah', _data!.namaNasabah!),
                        const Divider(height: 24),
                        for (final item in _data!.items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.namaKategori ?? '-',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  '${Formatters.kg(item.beratKg)} kg\n${Formatters.poin(item.subtotalPoin)} poin',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.subtle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Divider(height: 24),
                        _row(
                          'Total Berat',
                          '${Formatters.kg(_data!.totalBeratKg)} kg',
                        ),
                        _row(
                          'Total Poin',
                          '${Formatters.poin(_data!.totalPoin)} poin',
                        ),
                        if (_data!.catatan != null &&
                            _data!.catatan!.isNotEmpty)
                          _row('Catatan', _data!.catatan!),
                        if (_data!.catatanAdmin != null &&
                            _data!.catatanAdmin!.isNotEmpty)
                          _row('Catatan Admin', _data!.catatanAdmin!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
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
                              : const Icon(Icons.save_alt_outlined),
                          label: const Text('Simpan'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _exporting
                              ? null
                              : () => _pickReceiptExport(share: true),
                          icon: _exporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.share_outlined),
                          label: const Text('Bagikan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.subtle, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

/// Printable nota / struk for penukaran poin (UKK Nasabah #8).
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

  /// Waits for the widget tree to be fully laid out and painted before
  /// capturing, then converts the [RepaintBoundary] into PNG bytes.
  Future<Uint8List?> _captureImageBytes() async {
    await SchedulerBinding.instance.endOfFrame;
    await SchedulerBinding.instance.endOfFrame;

    final renderObject = _receiptKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;

    if (renderObject.debugNeedsPaint) {
      await SchedulerBinding.instance.endOfFrame;
    }

    final image = await renderObject.toImage(
      pixelRatio: ui.window.devicePixelRatio.clamp(2.0, 4.0),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<Uint8List> _wrapImageAsPdf(Uint8List pngBytes) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(pngBytes);
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
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
        showFeedback(context, 'Gagal membuat nota visual. Coba lagi.');
        return;
      }

      final fileName =
          'nota_penukaran_${DateTime.now().millisecondsSinceEpoch}.${asPdf ? 'pdf' : 'png'}';

      if (asPdf) {
        final pdfBytes = await _wrapImageAsPdf(bytes);
        final dir =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final file = File('${dir.path}${Platform.pathSeparator}$fileName');
        await file.writeAsBytes(pdfBytes);
        if (!mounted) return;
        showFeedback(context, 'PDF nota tersimpan di ${dir.path}');
      } else {
        final location = await _saveBytesToDevice(bytes, fileName);
        if (!mounted) return;
        showFeedback(
          context,
          _supportsGallery
              ? 'Gambar nota tersimpan di galeri.'
              : 'Gambar nota tersimpan di $location',
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
        showFeedback(context, 'Gagal menyiapkan nota untuk dibagikan.');
        return;
      }

      final fileName =
          'nota_penukaran_share_${DateTime.now().millisecondsSinceEpoch}.${asPdf ? 'pdf' : 'png'}';
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
        ], text: 'Nota penukaran poin');
      } else {
        await _revealInFileExplorer(file.path);
        if (!mounted) return;
        showFeedback(
          context,
          'File disiapkan di folder. Seret file itu ke WhatsApp Desktop untuk mengirimnya.',
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _pickReceiptExport({required bool share}) async {
    final result = await showModalBottomSheet<_ReceiptExportType>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih format nota',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Gambar (.png)'),
                onTap: () => Navigator.pop(context, _ReceiptExportType.image),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('PDF'),
                onTap: () => Navigator.pop(context, _ReceiptExportType.pdf),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || result == null) return;

    if (share) {
      await _shareReceiptImage(_data!, asPdf: result == _ReceiptExportType.pdf);
    } else {
      await _saveReceiptImage(_data!, asPdf: result == _ReceiptExportType.pdf);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nota Penukaran')),
      body: StateContainer(
        loading: _loading,
        error: _error,
        isEmpty: false,
        onRetry: _load,
        child: _data == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  RepaintBoundary(
                    key: _receiptKey,
                    child: _ReceiptCard(
                      title: 'BANK SAMPAH',
                      subtitle: 'Bukti Penukaran Poin',
                      children: [
                        _row('Kode', _data!.kodePenukaran),
                        _row('Tanggal', Formatters.dateTime(_data!.tanggal)),
                        _row('Status', StatusStyle.penukaran(_data!.status).$1),
                        if (_data!.namaNasabah != null)
                          _row('Nasabah', _data!.namaNasabah!),
                        _row('Hadiah', _data!.namaHadiah ?? '-'),
                        _row(
                          'Poin Terpakai',
                          '-${Formatters.poin(_data!.poinTerpakai)} poin',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
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
                              : const Icon(Icons.save_alt_outlined),
                          label: const Text('Simpan'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _exporting
                              ? null
                              : () => _pickReceiptExport(share: true),
                          icon: _exporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.share_outlined),
                          label: const Text('Bagikan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.subtle, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

enum _ReceiptExportType { image, pdf }

/// Whether the current platform has an OS-level photo gallery that `gal`
/// can write to. Windows and Linux desktop don't have this concept, so
/// files there are saved to the user's Downloads folder instead.
bool get _supportsGallery {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}

/// Whether the OS has a real share sheet that third-party apps (like
/// WhatsApp) register with to receive shared files. Windows desktop apps
/// like WhatsApp Desktop are plain Win32 apps and do NOT register for the
/// Windows share contract, so `Share.shareXFiles` silently sends only the
/// caption text there with no attachment. Same story on Linux. Android,
/// iOS and macOS all have working native share sheets.
bool get _supportsNativeFileShare {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}

/// Opens the OS file explorer with [filePath] pre-selected, so the user
/// can drag it into WhatsApp Desktop (or any other app) manually — the
/// only reliable way to hand off a file to non-UWP Windows apps.
Future<void> _revealInFileExplorer(String filePath) async {
  if (Platform.isWindows) {
    await Process.run('explorer.exe', ['/select,', filePath]);
  } else if (Platform.isLinux) {
    final dir = File(filePath).parent.path;
    await Process.run('xdg-open', [dir]);
  }
}

/// Saves [bytes] to the platform-appropriate location:
/// - Android/iOS/macOS: the OS photo gallery, via `gal`.
/// - Windows/Linux: the Downloads folder, via `path_provider`.
/// Returns a human-readable description of where the file ended up, for
/// the confirmation message.
Future<String> _saveBytesToDevice(Uint8List bytes, String fileName) async {
  if (_supportsGallery) {
    final hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      final granted = await Gal.requestAccess();
      if (!granted) {
        throw StateError('Izin akses galeri ditolak.');
      }
    }
    await Gal.putImageBytes(bytes, name: fileName);
    return 'galeri';
  }

  // Desktop (Windows/Linux): no gallery concept, so write straight to
  // the user's Downloads folder.
  final dir =
      await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes);
  return dir.path;
}

class _ReceiptCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _ReceiptCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppTheme.green,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.subtle, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
