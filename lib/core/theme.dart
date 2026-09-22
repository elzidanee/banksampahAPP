import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Central visual system - clean, authentic, human-crafted modern UI.
class AppTheme {
  AppTheme._();

  // Refined emerald / forest green palette (anti-slop, clean and natural)
  static const Color green = Color(0xFF16A34A); // Emerald 600
  static const Color greenDark = Color(0xFF15803D); // Emerald 700
  static const Color greenDeep = Color(0xFF14532D); // Emerald 900
  static const Color greenLight = Color(0xFFF0FDF4); // Emerald 50
  static const Color greenBorder = Color(0xFFBBF7D0); // Emerald 200
  static const Color greenMid = Color(0xFF22C55E); // Emerald 500
  static const Color greenAccent = Color(0xFF4ADE80);

  // Functional accent colors
  static const Color amber = Color(0xFFD97706); // Amber 600
  static const Color amberLight = Color(0xFFFEF3C7); // Amber 100
  static const Color blue = Color(0xFF2563EB); // Blue 600
  static const Color blueLight = Color(0xFFEFF6FF); // Blue 50
  static const Color red = Color(0xFFDC2626); // Red 600
  static const Color redLight = Color(0xFFFEF2F2); // Red 50

  // Neutral slate text hierarchy
  static const Color ink = Color(0xFF0F172A); // Slate 900
  static const Color inkMedium = Color(0xFF334155); // Slate 700
  static const Color subtle = Color(0xFF64748B); // Slate 500
  static const Color subtleLighter = Color(0xFF94A3B8); // Slate 400

  // Surfaces & Backgrounds
  static const Color bg = Color(0xFFF8FAFC); // Slate 50 - pristine neutral
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF1F5F9); // Slate 100
  static const Color surfaceHigh = Color(0xFFE2E8F0);
  static const Color line = Color(0xFFE2E8F0); // Slate 200 - crisp 1px border
  static const Color lineStrong = Color(0xFFCBD5E1); // Slate 300

  // Modern subtle gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F291E), Color(0xFF081C14)],
  );

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
  );

  // Clean, realistic shadows (no harsh artificial glowing halos)
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: .04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: .02),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> greenGlow = cardShadow;

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.poppins().fontFamily,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        primary: green,
        secondary: greenMid,
        brightness: Brightness.light,
        surface: surface,
        error: red,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bgWhite,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: ink, size: 22),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(const TextTheme(
        headlineSmall: TextStyle(color: ink, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: ink, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: inkMedium),
        bodyMedium: TextStyle(color: inkMedium),
        bodySmall: TextStyle(color: subtle),
        labelLarge: TextStyle(color: ink, fontWeight: FontWeight.w600),
      )),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: line, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: green, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: red, width: 1),
        ),
        hintStyle: const TextStyle(color: subtleLighter, fontSize: 13.5),
        labelStyle: const TextStyle(color: subtle, fontSize: 13.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: green,
          side: const BorderSide(color: line, width: 1),
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: green,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: line),
        ),
        labelStyle: const TextStyle(fontSize: 11.5, color: inkMedium),
      ),
      dividerTheme: const DividerThemeData(color: line, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: greenLight,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ink),
        ),
        iconTheme: const WidgetStatePropertyAll(
          IconThemeData(color: subtle),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        showDragHandle: true,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
    );
  }
}

/// Status label and color mapping for chips across the app.
class StatusStyle {
  static (String, Color) setor(String s) => switch (s) {
    'menunggu_konfirmasi' => ('Menunggu Konfirmasi', AppTheme.amber),
    'diverifikasi' => ('Diverifikasi', AppTheme.blue),
    'selesai' => ('Selesai', AppTheme.green),
    'ditolak' => ('Ditolak', AppTheme.red),
    _ => (s.isEmpty ? '-' : s, AppTheme.subtle),
  };

  static (String, Color) penukaran(String s) => switch (s) {
    'diproses' => ('Diproses', AppTheme.amber),
    'selesai' => ('Selesai', AppTheme.green),
    _ => (s.isEmpty ? '-' : s, AppTheme.subtle),
  };
}

class Formatters {
  Formatters._();

  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0,
  );
  static final NumberFormat _decimal = NumberFormat.decimalPattern('id_ID');

  static String rupiah(num? v) => _rupiah.format(v ?? 0);

  static String kg(num? v) {
    if (v == null) return '0';
    final d = v.toDouble();
    return d == d.truncateToDouble()
        ? _decimal.format(d.toInt())
        : _decimal.format(d);
  }

  static String poin(num? v) => _decimal.format(v ?? 0);

  static String date(String? iso) {
    final d = _tryParse(iso);
    return d == null ? '-' : DateFormat('d MMM yyyy', 'id_ID').format(d);
  }

  static String dateTime(String? iso) {
    final d = _tryParse(iso);
    return d == null ? '-' : DateFormat('d MMM yyyy HH:mm', 'id_ID').format(d);
  }

  static DateTime? _tryParse(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }

  static String isoNow() => DateTime.now().toUtc().toIso8601String();

  static String bulanQuery(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  static List<String> get monthNames => const [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
}
