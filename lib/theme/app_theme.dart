import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Berry Blue Palette ──────────────────────────────────────────────
  static const Color deepBerry       = Color(0xFF3B0764);
  static const Color primaryViolet   = Color(0xFF6D28D9);
  static const Color accentPurple    = Color(0xFF7C3AED);
  static const Color softViolet      = Color(0xFFA855F7);
  static const Color berryBlue       = Color(0xFF4F46E5);
  static const Color indigoLight     = Color(0xFF818CF8);

  // Berry pops
  static const Color berryPink       = Color(0xFFBE185D);
  static const Color accentRose      = Color(0xFFEC4899);

  // Lavender surfaces
  static const Color lavenderMist    = Color(0xFFDDD6FE);
  static const Color paleLavender    = Color(0xFFEDE9FE);
  static const Color backgroundFrost = Color(0xFFF5F3FF);

  // Semantic
  static const Color successGreen    = Color(0xFF059669);
  static const Color warningAmber    = Color(0xFFD97706);
  static const Color errorRed        = Color(0xFFDC2626);
  static const Color infoBlue        = Color(0xFF0284C7);

  // Neutrals
  static const Color textDark        = Color(0xFF1E1B4B);
  static const Color textMedium      = Color(0xFF4C1D95);
  static const Color textLight       = Color(0xFF7C3AED);
  static const Color cardWhite       = Color(0xFFFFFFFF);
  static const Color dividerLavender = Color(0xFFE9D5FF);

  // ── Legacy aliases (keeps all existing screens working) ─────────────
  static const Color backgroundWhite = backgroundFrost;
  static const Color paleBlue        = paleLavender;
  static const Color primaryBlue     = primaryViolet;
  static const Color warningOrange   = warningAmber;
  static const Color accentTeal      = berryBlue;
  static const Color dividerGray     = dividerLavender;

  // ── Gradients ───────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepBerry, primaryViolet, berryBlue],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [paleLavender, lavenderMist, backgroundFrost],
  );

  static const LinearGradient berryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [berryPink, accentPurple, berryBlue],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPurple, softViolet, indigoLight],
  );

  // Legacy gradient alias
  static const LinearGradient lightGradient = softGradient;

  // ── Shadows ─────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: accentPurple.withOpacity(0.10),
      blurRadius: 24,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: berryBlue.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: accentPurple.withOpacity(0.35),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: deepBerry.withOpacity(0.20),
      blurRadius: 32,
      offset: const Offset(0, 10),
    ),
  ];

  // ── Text Theme ───────────────────────────────────────────────────────
  static TextTheme get _textTheme => TextTheme(
    displayLarge: GoogleFonts.poppins(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: textDark,
      letterSpacing: -1.0,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: textDark,
      letterSpacing: -0.5,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: textDark,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: textDark,
    ),
    titleLarge: GoogleFonts.nunito(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: textDark,
    ),
    titleMedium: GoogleFonts.nunito(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: textDark,
    ),
    bodyLarge: GoogleFonts.nunito(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: textDark,
    ),
    bodyMedium: GoogleFonts.nunito(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: textMedium,
    ),
    bodySmall: GoogleFonts.nunito(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: textLight,
    ),
    labelLarge: GoogleFonts.nunito(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: cardWhite,
    ),
  );

  // ── Light Theme ──────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryViolet,
        secondary: berryBlue,
        tertiary: accentRose,
        surface: cardWhite,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: textDark,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundFrost,
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
        titleTextStyle: GoogleFonts.poppins(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        color: cardWhite,
        shadowColor: accentPurple.withOpacity(0.12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: paleLavender,
        selectedColor: accentPurple,
        labelStyle: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: primaryViolet,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        side: const BorderSide(color: lavenderMist),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: dividerLavender, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: dividerLavender, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: accentPurple, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        labelStyle: GoogleFonts.nunito(color: textLight, fontWeight: FontWeight.w600),
        hintStyle: GoogleFonts.nunito(color: lavenderMist, fontWeight: FontWeight.w500),
        prefixIconColor: accentPurple,
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accentPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentPurple,
          side: const BorderSide(color: accentPurple, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentPurple,
          textStyle: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentPurple,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardWhite,
        selectedItemColor: accentPurple,
        unselectedItemColor: lavenderMist,
        selectedLabelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        elevation: 12,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: dividerLavender,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: deepBerry,
        contentTextStyle: GoogleFonts.nunito(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
