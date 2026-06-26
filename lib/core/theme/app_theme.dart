import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF074173);
  static const Color secondary = Color(0xFF38A4C8);
  static const Color accent = Color(0xFFCBD5E1);
  static const Color dark = Color(0xFF020617);
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color gradientStart = Color(0xFF074173);
  static const Color gradientEnd = Color(0xFF38A4C8);
  // Pre-computed opacity variants so withOpacity() is never called in build()
  static const Color whiteMuted = Color(0xBFFFFFFF);    // white 75%
  static const Color whiteFaint = Color(0x26FFFFFF);    // white 15%
  static const Color darkShadow = Color(0x10020617);    // dark 6%
  static const Color darkShadowMd = Color(0x12020617);  // dark 7%
  static const Color primaryFaint = Color(0x14074173);  // primary 8%
  static const Color primaryLight = Color(0x1A074173);  // primary 10%
  static const Color successFaint = Color(0x1F10B981);  // success 12%
  static const Color errorFaint = Color(0x1FEF4444);    // error 12%
  static const Color warningFaint = Color(0x1FF59E0B);  // warning 12%
}

/// Pre-computed TextStyles — computed once, never recreated on rebuild.
class T {
  static final sectionTitle = GoogleFonts.urbanist(
      fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.dark);
  static final seeAll = GoogleFonts.urbanist(
      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondary);
  static final cardTitle = GoogleFonts.urbanist(
      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark);
  static final cardTitleSm = GoogleFonts.urbanist(
      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.dark);
  static final cardTitleXs = GoogleFonts.urbanist(
      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark);
  static final priceLg = GoogleFonts.urbanist(
      fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary);
  static final priceMd = GoogleFonts.urbanist(
      fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary);
  static final location = GoogleFonts.urbanist(
      fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  static final locationSm = GoogleFonts.urbanist(
      fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  static final locationXs = GoogleFonts.urbanist(
      fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  static final badgeWhite = GoogleFonts.urbanist(
      fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.white);
  static final badgeWhiteSm = GoogleFonts.urbanist(
      fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.white);
  static final badgeWhiteXs = GoogleFonts.urbanist(
      fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.white);
  static final specText = GoogleFonts.urbanist(
      fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  static final detailsBtn = GoogleFonts.urbanist(
      fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary);
  static final searchHint = GoogleFonts.urbanist(
      fontSize: 13, color: AppColors.textTertiary);
  static final headerGoodDay = GoogleFonts.urbanist(
      fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.whiteMuted);
  static final headerTitle = GoogleFonts.urbanist(
      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white);
  static final navActive = GoogleFonts.urbanist(
      fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary);
  static final navInactive = GoogleFonts.urbanist(
      fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textTertiary);
  static final typeActive = GoogleFonts.urbanist(
      fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.white);
  static final typeInactive = GoogleFonts.urbanist(
      fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary);
  static final ratingNum = GoogleFonts.urbanist(
      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.dark);
  static final ratingCount = GoogleFonts.urbanist(
      fontSize: 10, color: AppColors.textSecondary);
  static final ratingNumSm = GoogleFonts.urbanist(
      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.dark);
  static final emptyState = GoogleFonts.urbanist(
      fontSize: 14, color: AppColors.textSecondary);
  static final mapLabel = GoogleFonts.urbanist(
      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary);
  static final verified = GoogleFonts.urbanist(
      fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success);
  static final stayBadge = GoogleFonts.urbanist(
      fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.white);
  static final stayPrice = GoogleFonts.urbanist(
      fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary);
}

class AppTheme {
  static TextTheme get _textTheme => GoogleFonts.urbanistTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.dark),
          displayMedium: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.dark),
          displaySmall: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.dark),
          headlineLarge: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.dark),
          headlineMedium: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.dark),
          headlineSmall: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.dark),
          titleLarge: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.dark),
          titleMedium: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark),
          titleSmall: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.dark),
          bodyLarge: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.dark),
          bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary),
          bodySmall: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textTertiary),
          labelLarge: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white),
          labelMedium: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.white),
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.white,
          error: AppColors.error,
          onPrimary: AppColors.white,
          onSecondary: AppColors.white,
          onSurface: AppColors.dark,
        ),
        textTheme: _textTheme,
        scaffoldBackgroundColor: AppColors.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: GoogleFonts.urbanist(
            color: AppColors.dark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: const IconThemeData(color: AppColors.dark),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            minimumSize: const Size(double.infinity, 56),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            textStyle: GoogleFonts.urbanist(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 56),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.urbanist(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.secondary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: GoogleFonts.urbanist(
              color: AppColors.textTertiary, fontSize: 14),
          labelStyle: GoogleFonts.urbanist(
              color: AppColors.textSecondary, fontSize: 14),
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.primary,
          labelStyle:
              GoogleFonts.urbanist(fontSize: 12, fontWeight: FontWeight.w500),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          selectedLabelStyle: GoogleFonts.urbanist(
              fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.urbanist(
              fontSize: 11, fontWeight: FontWeight.w500),
          type: BottomNavigationBarType.fixed,
          elevation: 12,
        ),
      );
}
