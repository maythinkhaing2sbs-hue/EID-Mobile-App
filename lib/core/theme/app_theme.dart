import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light(Locale locale) {
    final TextTheme text = AppTypography.forLocale(locale);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surfaceMuted,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.secondary,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.primaryDark,
        onSecondary: AppColors.textOnPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceSunken,
        error: AppColors.danger,
        onError: AppColors.textOnPrimary,
        outline: AppColors.borderStrong,
        outlineVariant: AppColors.border,
      ),
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: Radii.cardAll),
      ),

      // Pill-shaped primary action, full width, 56 high — thumb-reachable and
      // unmistakable as "the next step".
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.borderStrong,
          disabledForegroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: Radii.pill),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
          textStyle: text.labelLarge,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: Radii.pill),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: text.labelLarge,
          minimumSize: const Size(kMinTapTarget, kMinTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: Gap.md),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.lg),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: text.bodyMedium,
        floatingLabelStyle: text.labelMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: AppColors.textTertiary),
        helperStyle: text.labelSmall,
        errorStyle: text.labelSmall?.copyWith(color: AppColors.danger),
        border: const OutlineInputBorder(
          borderRadius: Radii.fieldAll,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: Radii.fieldAll,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: Radii.fieldAll,
          borderSide: BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: Radii.fieldAll,
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: Radii.fieldAll,
          borderSide: BorderSide(color: AppColors.danger, width: 1.8),
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : Colors.transparent),
        side: const BorderSide(color: AppColors.borderStrong, width: 1.6),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle:
            text.bodyMedium?.copyWith(color: AppColors.textOnPrimary),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Radii.fieldAll),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceSunken,
        circularTrackColor: AppColors.surfaceSunken,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
