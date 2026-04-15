import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:twsnmpfm/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twsnmpfm/node_list_page.dart';
import 'package:dart_ping_ios/dart_ping_ios.dart';
import 'package:twsnmpfm/settings.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isIOS || Platform.isMacOS) {
    DartPingIOS.register();
  }
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// ─── TWSNMP Blueprint デザインシステム ────────────────────────────────────────
// Primary: #1565C0 (Deep Blue)  Seed: #004d99
// Tertiary: #2E7D32 (Green for status OK)
// Error: #BA1A1A
// Font: Inter (google_fonts)
// Shape: cornerRadius 8px (Medium)
// ─────────────────────────────────────────────────────────────────────────────

const _primaryColor = Color(0xFF1565C0);
const _seedColor = Color(0xFF004D99);
const _errorColor = Color(0xFFBA1A1A);

// ステータスカラー (全画面で共用できるよう定数として定義)
const statusGreen = Color(0xFF4CAF50);
const statusRed = Color(0xFFF44336);
const statusAmber = Color(0xFFFF9800);

ThemeData _buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.light,
    primary: _primaryColor,
    error: _errorColor,
    // Surface 階層 (ボーダー線の代わりに色差で区切る "No-Line Rule")
    surface: const Color(0xFFF9F9FF),
    onSurface: const Color(0xFF191C21),
    surfaceContainerLowest: const Color(0xFFFFFFFF),
    surfaceContainerLow: const Color(0xFFF2F3FB),
    surfaceContainer: const Color(0xFFECEDF6),
    surfaceContainerHigh: const Color(0xFFE7E8F0),
    surfaceContainerHighest: const Color(0xFFE1E2EA),
  );

  final textTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    // AppBar: プライマリカラー背景、白テキスト
    appBarTheme: AppBarTheme(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02,
      ),
    ),
    // FAB: プライマリカラー
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    // カード: 白, 角丸8px, 微細な影
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF),
      elevation: 1,
      shadowColor: const Color(0xFF191C21).withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    // ListTile: 選択時は primaryContainer
    listTileTheme: const ListTileThemeData(
      selectedColor: _primaryColor,
    ),
    // ElevatedButton: プライマリグラデーション風
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
    // TextButton
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    // InputDecoration: ボーダーなし塗り潰し
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFE7E8F0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _primaryColor.withValues(alpha: 0.4), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _errorColor, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    // Slider: プライマリ色
    sliderTheme: SliderThemeData(
      activeTrackColor: _primaryColor,
      thumbColor: _primaryColor,
      overlayColor: _primaryColor.withValues(alpha: 0.12),
    ),
    // Switch: プライマリ色
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? _primaryColor : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? _primaryColor.withValues(alpha: 0.5)
            : const Color(0xFFE1E2EA),
      ),
    ),
    // TabBar
    tabBarTheme: TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
      indicatorColor: Colors.white,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
    ),
    // DataTable
    dataTableTheme: DataTableThemeData(
      headingTextStyle: GoogleFonts.inter(
        color: const Color(0xFF424752),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      dataTextStyle: GoogleFonts.inter(
        color: const Color(0xFF191C21),
        fontSize: 12,
      ),
      headingRowColor: WidgetStateProperty.all(const Color(0xFFECEDF6)),
      dataRowColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xFFD6E3FF)
            : null,
      ),
    ),
    // DropdownButton
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFE7E8F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    ),
    // Popup Menu
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xFFFFFFFF),
      elevation: 4,
      shadowColor: const Color(0xFF191C21).withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    // Scaffold 背景
    scaffoldBackgroundColor: const Color(0xFFF2F3FB),
    dividerColor: Colors.transparent,
  );
}

ThemeData _buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
    primary: const Color(0xFF90CAF9),       // ライトブルー (ダーク上で視認性)
    onPrimary: const Color(0xFF001B3D),
    primaryContainer: _primaryColor,
    onPrimaryContainer: const Color(0xFFDAE5FF),
    secondary: const Color(0xFFB2C7F1),
    error: const Color(0xFFFFB4AB),
    onError: const Color(0xFF690005),
    errorContainer: const Color(0xFF93000A),
    // Surface 階層 (GitHub Dark 風)
    surface: const Color(0xFF0D1117),
    onSurface: const Color(0xFFE6EDF3),
    surfaceContainerLowest: const Color(0xFF010409),
    surfaceContainerLow: const Color(0xFF161B22),
    surfaceContainer: const Color(0xFF1C2128),
    surfaceContainerHigh: const Color(0xFF21262D),
    surfaceContainerHighest: const Color(0xFF30363D),
    outline: const Color(0xFF30363D),
    onSurfaceVariant: const Color(0xFF848D97),
  );

  final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    // AppBar: ダークネイビー
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF161B22),
      foregroundColor: const Color(0xFFE6EDF3),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        color: const Color(0xFFE6EDF3),
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02,
      ),
    ),
    // FAB: グラデーションブルー
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    // カード: #1C2128 (GitHub Dark card)
    cardTheme: CardThemeData(
      color: const Color(0xFF1C2128),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF30363D), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    // ListTile
    listTileTheme: const ListTileThemeData(
      selectedColor: Color(0xFF90CAF9),
    ),
    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
    // TextButton
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF90CAF9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    // InputDecoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF21262D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF30363D), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF30363D), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF90CAF9), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFFB4AB), width: 1),
      ),
      labelStyle: const TextStyle(color: Color(0xFF848D97)),
      hintStyle: const TextStyle(color: Color(0xFF848D97)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    // Slider
    sliderTheme: SliderThemeData(
      activeTrackColor: const Color(0xFF90CAF9),
      thumbColor: const Color(0xFF90CAF9),
      overlayColor: const Color(0xFF90CAF9).withValues(alpha: 0.12),
      inactiveTrackColor: const Color(0xFF30363D),
    ),
    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xFF90CAF9)
            : const Color(0xFF848D97),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xFF1565C0)
            : const Color(0xFF30363D),
      ),
    ),
    // TabBar
    tabBarTheme: TabBarThemeData(
      labelColor: const Color(0xFF90CAF9),
      unselectedLabelColor: const Color(0xFF848D97),
      indicatorColor: const Color(0xFF90CAF9),
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
    ),
    // DataTable
    dataTableTheme: DataTableThemeData(
      headingTextStyle: GoogleFonts.inter(
        color: const Color(0xFF90CAF9),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      dataTextStyle: GoogleFonts.inter(
        color: const Color(0xFFE6EDF3),
        fontSize: 12,
      ),
      headingRowColor: WidgetStateProperty.all(const Color(0xFF21262D)),
      dataRowColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xFF1C2128)
            : null,
      ),
    ),
    // Popup Menu
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xFF1C2128),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF30363D), width: 1),
      ),
    ),
    // Scaffold 背景
    scaffoldBackgroundColor: const Color(0xFF0D1117),
    dividerColor: const Color(0xFF30363D),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      title: 'TWSNMP FM',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: settings.themeMode,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English, no country code
        Locale('ja', ''), // 日本語, no country code
      ],
      home: const NodeListPage(),
    );
  }
}
