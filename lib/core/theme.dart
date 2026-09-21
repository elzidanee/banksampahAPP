import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Central visual system - light, fresh, eco-friendly UI.
class AppTheme {
  AppTheme._();

  // Core greens
  static const Color green = Color(0xFF2E9E50);
  static const Color greenDark = Color(0xFF1E7A3C);
  static const Color greenLight = Color(0xFFE8F5ED);
  static const Color greenMid = Color(0xFF3DB866);
  static const Color greenAccent = Color(0xFF4CD97B);

  // Accent colors
  static const Color amber = Color(0xFFE09000);
  static const Color amberLight = Color(0xFFFFF3D6);
  static const Color blue = Color(0xFF1A7FBA);
  static const Color blueLight = Color(0xFFE3F2FD);
  static const Color red = Color(0xFFD93025);
  static const Color redLight = Color(0xFFFDECEB);

  // Text colors
  static const Color ink = Color(0xFF111827);
  static const Color inkMedium = Color(0xFF374151);
  static const Color subtle = Color(0xFF6B7280);
  static const Color subtleLighter = Color(0xFF9CA3AF);

  // Background / Surface
  static const Color bg = Color(0xFFF4F7F5);
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF0F4F1);
  static const Color surfaceHigh = Color(0xFFE8EEE9);
  static const Color line = Color(0xFFE5EBE6);
  static const Color lineStrong = Color(0xFFD1D9D3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3DB866), Color(0xFF1E7A3C)],
  );

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFECF5EE), Color(0xFFF4F7F5)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E9E50), Color(0xFF1E7A3C)],
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFF5A623), Color(0xFFE09000)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
  );

  // Shadows
  static List<BoxShadow> greenGlow = [
    BoxShadow(
      color: Color(0xFF2E9E50).withValues(alpha: .25),
      blurRadius: 20,
      spreadRadius: -4,
      offset: Offset(0, 6),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0xFF1A3A23).withValues(alpha: .08),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0xFF1A3A23).withValues(alpha: .04),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

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
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x14000000),
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: ink),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(const TextTheme(
        headlineSmall: TextStyle(color: ink, fontWeight: FontWeight.w800),
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
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: line),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: green, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: red),
        ),
        hintStyle: const TextStyle(color: subtleLighter, fontSize: 14),
        labelStyle: const TextStyle(color: subtle, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: green,
          side: const BorderSide(color: green),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: green),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(fontSize: 11, color: inkMedium),
      ),
      dividerTheme: const DividerThemeData(color: line, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: greenLight,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ink),
        ),
        iconTheme: WidgetStatePropertyAll(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 4,
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
