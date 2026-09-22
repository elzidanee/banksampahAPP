import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import 'app_config.dart';
import 'theme.dart';

String? resolveImageUrl(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final raw = value.trim();
  final parsed = Uri.tryParse(raw);
  if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
    return raw;
  }

  final base = Uri.parse(AppConfig.apiBaseUrl);
  final path = base.path.replaceFirst(RegExp(r'/api/v1/?$'), '');
  final relative = raw.startsWith('/') ? raw : '/$raw';
  return base.replace(path: '$path$relative').toString();
}

/// Loading / error / empty / content state container used by every list page.
class StateContainer extends StatelessWidget {
  final bool loading;
  final String? error;
  final bool isEmpty;
  final Widget? loader;
  final VoidCallback? onRetry;
  final Widget child;
  final String? emptyTitle;
  final String? emptyMessage;

  const StateContainer({
    super.key,
    required this.loading,
    required this.child,
    this.error,
    this.isEmpty = false,
    this.onRetry,
    this.loader,
    this.emptyTitle,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            loader ?? const CircularProgressIndicator(color: AppTheme.green),
            const SizedBox(height: 12),
            Text(
              'Memuat data...',
              style: TextStyle(color: AppTheme.subtle, fontSize: 13),
            ),
          ],
        ),
      );
    }
    if (error != null) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        color: AppTheme.red,
        title: 'Terjadi Kesalahan',
        message: error!,
        actionLabel: onRetry != null ? 'Coba Lagi' : null,
        onAction: onRetry,
      );
    }
    if (isEmpty) {
      return _Message(
        icon: Icons.inbox_outlined,
        color: AppTheme.subtle,
        title: emptyTitle ?? 'Belum Ada Data',
        message: emptyMessage ?? 'Data akan muncul di sini setelah tersedia.',
      );
    }
    return child;
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.subtle, fontSize: 13),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Colored status chip with clean indicator dot.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .22), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5.5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded square image with safe fallback when [url] is null/unloadable.
class SafeImage extends StatelessWidget {
  final String? url;
  final double size;
  final IconData fallbackIcon;
  final BorderRadius? borderRadius;

  const SafeImage({
    super.key,
    required this.url,
    this.size = 48,
    this.fallbackIcon = Icons.image_outlined,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(10);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: resolveImageUrl(url) == null
            ? _placeholder()
            : Image.network(
                resolveImageUrl(url)!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppTheme.surfaceElevated,
    child: Icon(fallbackIcon, color: AppTheme.green, size: size * .45),
  );
}

/// Shows consistent toast feedback without changing the caller's flow.
void showFeedback(BuildContext context, String message, {bool error = false}) {
  toastification.show(
    context: context,
    type: error ? ToastificationType.error : ToastificationType.success,
    style: ToastificationStyle.flatColored,
    alignment: Alignment.topCenter,
    autoCloseDuration: const Duration(seconds: 3),
    title: Text(error ? 'Gagal' : 'Berhasil'),
    description: Text(message),
    showProgressBar: false,
    closeOnClick: true,
    dragToClose: true,
  );
}

/// Month picker bottom sheet returning DateTime (first day of picked month),
/// or null when cancelled. Used by all ?bulan=YYYY-MM filters.
Future<DateTime?> pickMonth(BuildContext context, DateTime initial) async {
  var year = initial.year;
  var month = initial.month;
  return showModalBottomSheet<DateTime>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => setSheetState(() => year -= 1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      '$year',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setSheetState(() => year += 1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    childAspectRatio: 2.4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (var m = 1; m <= 12; m++)
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            backgroundColor: (m == month)
                                ? AppTheme.greenLight
                                : AppTheme.surface,
                          ),
                          onPressed: () {
                            month = m;
                            Navigator.pop(context, DateTime(year, month));
                          },
                          child: Text(Formatters.monthNames[m - 1]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
