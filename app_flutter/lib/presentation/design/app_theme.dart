import 'package:flutter/material.dart';

/// Identidade provisória: concentre aqui a futura troca de marca.
abstract final class AppBrand {
  static const name = 'Gestão da clínica';
  static const blue = Color(0xFF225CC5);
  static const navy = Color(0xFF173567);
  static const canvas = Color(0xFFF3F7FC);
  static const pale = Color(0xFFE8F0FF);
  static const line = Color(0xFFDCE5F1);
  static const radius = 20.0;
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, blue],
  );

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(seedColor: blue).copyWith(
      primary: blue,
      secondary: blue,
      secondaryContainer: pale,
      onSecondaryContainer: navy,
      onPrimary: Colors.white,
      primaryContainer: pale,
      onPrimaryContainer: navy,
      surface: Colors.white,
      onSurface: const Color(0xFF192D48),
      onSurfaceVariant: const Color(0xFF52647C),
      outlineVariant: line,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final input = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: line),
    );
    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -.5,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape.copyWith(side: const BorderSide(color: line)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: canvas,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: input,
        enabledBorder: input,
        focusedBorder: input.copyWith(
          borderSide: const BorderSide(color: blue, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: shape,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: navy,
          fontWeight: FontWeight.w700,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: shape,
      ),
      navigationDrawerTheme: const NavigationDrawerThemeData(
        backgroundColor: Colors.white,
        indicatorColor: pale,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: pale,
        selectedIconTheme: IconThemeData(color: blue),
        selectedLabelTextStyle: TextStyle(
          color: navy,
          fontWeight: FontWeight.w700,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        iconColor: blue,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: navy,
        shape: shape,
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        shape: shape,
      ),
    );
  }
}
