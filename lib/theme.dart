import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ===============================
///   PALETA PRINCIPAL VERSEE
/// ===============================
class LightModeColors {
  // Primária
  static const lightPrimary = Color(0xFF3950FF);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFE4E8FF);
  static const lightOnPrimaryContainer = Color(0xFF0C1A5C);

  // Secundária
  static const lightSecondary = Color(0xFF6B7280);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightSecondaryContainer = Color(0xFFE5E7EB);
  static const lightOnSecondaryContainer = Color(0xFF1F2937);

  // Terciária
  static const lightTertiary = Color(0xFF4A6BFF);
  static const lightOnTertiary = Color(0xFFFFFFFF);

  // Estados
  static const lightSuccess = Color(0xFF22C55E);
  static const lightOnSuccess = Color(0xFFFFFFFF);
  static const lightWarning = Color(0xFFF59E0B);
  static const lightOnWarning = Color(0xFF1F1F1F);
  static const lightInfo = Color(0xFF3B82F6);
  static const lightOnInfo = Color(0xFFFFFFFF);

  // Erro
  static const lightError = Color(0xFFBA1A1A);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFDAD6);
  static const lightOnErrorContainer = Color(0xFF410002);

  // Outros
  static const lightInversePrimary = Color(0xFFB3BEFF);
  static const lightShadow = Color(0xFF000000);
  static const lightSurface = Color(0xFFFAFAFA);
  static const lightOnSurface = Color(0xFF1C1C1C);
  static const lightAppBarBackground = Color(0xFFE4E8FF);
}

class DarkModeColors {
  // Primária
  static const darkPrimary = Color(0xFF3950FF);
  static const darkOnPrimary = Color(0xFFFFFFFF);
  static const darkPrimaryContainer = Color(0xFF1B255B);
  static const darkOnPrimaryContainer = Color(0xFFDDE1FF);

  // Secundária
  static const darkSecondary = Color(0xFF9CA3AF);
  static const darkOnSecondary = Color(0xFF1F1F1F);
  static const darkSecondaryContainer = Color(0xFF374151);
  static const darkOnSecondaryContainer = Color(0xFFE5E7EB);

  // Terciária
  static const darkTertiary = Color(0xFF6B82FF);
  static const darkOnTertiary = Color(0xFFFFFFFF);

  // Estados
  static const darkSuccess = Color(0xFF22C55E);
  static const darkOnSuccess = Color(0xFFFFFFFF);
  static const darkWarning = Color(0xFFFBBF24);
  static const darkOnWarning = Color(0xFF1F1F1F);
  static const darkInfo = Color(0xFF60A5FA);
  static const darkOnInfo = Color(0xFF0F172A);

  // Erro
  static const darkError = Color(0xFFEF4444);
  static const darkOnError = Color(0xFFFFFFFF);
  static const darkErrorContainer = Color(0xFF7F1D1D);
  static const darkOnErrorContainer = Color(0xFFFEF2F2);

  // Outros
  static const darkInversePrimary = Color(0xFFB3BEFF);
  static const darkShadow = Color(0xFF000000);
  static const darkSurface = Color(0xFF0B0D12);
  static const darkOnSurface = Color(0xFFE2E8F0);
  static const darkAppBarBackground = Color(0xFF0B0D12);
}

/// ===============================
///   TIPOGRAFIA
/// ===============================
class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 24.0;
  static const double headlineSmall = 22.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double titleSmall = 16.0;
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

TextTheme get _textTheme => TextTheme(
  displayLarge: GoogleFonts.inter(fontSize: FontSizes.displayLarge, fontWeight: FontWeight.normal),
  displayMedium: GoogleFonts.inter(fontSize: FontSizes.displayMedium, fontWeight: FontWeight.normal),
  displaySmall: GoogleFonts.inter(fontSize: FontSizes.displaySmall, fontWeight: FontWeight.w600),
  headlineLarge: GoogleFonts.inter(fontSize: FontSizes.headlineLarge, fontWeight: FontWeight.normal),
  headlineMedium: GoogleFonts.inter(fontSize: FontSizes.headlineMedium, fontWeight: FontWeight.w500),
  headlineSmall: GoogleFonts.inter(fontSize: FontSizes.headlineSmall, fontWeight: FontWeight.bold),
  titleLarge: GoogleFonts.inter(fontSize: FontSizes.titleLarge, fontWeight: FontWeight.w500),
  titleMedium: GoogleFonts.inter(fontSize: FontSizes.titleMedium, fontWeight: FontWeight.w500),
  titleSmall: GoogleFonts.inter(fontSize: FontSizes.titleSmall, fontWeight: FontWeight.w500),
  labelLarge: GoogleFonts.inter(fontSize: FontSizes.labelLarge, fontWeight: FontWeight.w500),
  labelMedium: GoogleFonts.inter(fontSize: FontSizes.labelMedium, fontWeight: FontWeight.w500),
  labelSmall: GoogleFonts.inter(fontSize: FontSizes.labelSmall, fontWeight: FontWeight.w500),
  bodyLarge: GoogleFonts.inter(fontSize: FontSizes.bodyLarge, fontWeight: FontWeight.normal),
  bodyMedium: GoogleFonts.inter(fontSize: FontSizes.bodyMedium, fontWeight: FontWeight.normal),
  bodySmall: GoogleFonts.inter(fontSize: FontSizes.bodySmall, fontWeight: FontWeight.normal),
);

/// ===============================
///   TEMAS
/// ===============================
ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: LightModeColors.lightPrimary,
    onPrimary: LightModeColors.lightOnPrimary,
    primaryContainer: LightModeColors.lightPrimaryContainer,
    onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
    secondary: LightModeColors.lightSecondary,
    onSecondary: LightModeColors.lightOnSecondary,
    secondaryContainer: LightModeColors.lightSecondaryContainer,
    onSecondaryContainer: LightModeColors.lightOnSecondaryContainer,
    tertiary: LightModeColors.lightTertiary,
    onTertiary: LightModeColors.lightOnTertiary,
    error: LightModeColors.lightError,
    onError: LightModeColors.lightOnError,
    surface: LightModeColors.lightSurface,
    onSurface: LightModeColors.lightOnSurface,
    inversePrimary: LightModeColors.lightInversePrimary,
  ),
  brightness: Brightness.light,
  appBarTheme: AppBarTheme(
    backgroundColor: LightModeColors.lightAppBarBackground,
    foregroundColor: LightModeColors.lightOnPrimaryContainer,
    elevation: 0,
  ),
  textTheme: _textTheme,
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: DarkModeColors.darkPrimary,
    onPrimary: DarkModeColors.darkOnPrimary,
    primaryContainer: DarkModeColors.darkPrimaryContainer,
    onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
    secondary: DarkModeColors.darkSecondary,
    onSecondary: DarkModeColors.darkOnSecondary,
    secondaryContainer: DarkModeColors.darkSecondaryContainer,
    onSecondaryContainer: DarkModeColors.darkOnSecondaryContainer,
    tertiary: DarkModeColors.darkTertiary,
    onTertiary: DarkModeColors.darkOnTertiary,
    error: DarkModeColors.darkError,
    onError: DarkModeColors.darkOnError,
    surface: DarkModeColors.darkSurface,
    onSurface: DarkModeColors.darkOnSurface,
    inversePrimary: DarkModeColors.darkInversePrimary,
  ),
  brightness: Brightness.dark,
  appBarTheme: AppBarTheme(
    backgroundColor: DarkModeColors.darkAppBarBackground,
    foregroundColor: DarkModeColors.darkOnPrimaryContainer,
    elevation: 0,
  ),
  textTheme: _textTheme,
);