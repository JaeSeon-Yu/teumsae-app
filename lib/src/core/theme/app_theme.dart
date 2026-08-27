import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 앱 전역 테마. 웹(teumsae-web)과 같은 토큰을 사용합니다.
///
/// 다크 테마는 웹에도 아직 없어서 만들지 않았습니다.
/// 추가할 때는 웹 `globals.css`에 다크 토큰을 먼저 정의한 뒤 여기로 옮겨 주세요.
abstract final class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.brand500,
      onPrimary: Colors.white,
      primaryContainer: AppColors.brand50,
      onPrimaryContainer: AppColors.brand700,
      secondary: AppColors.brand600,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.fg,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.surfaceMuted,
      surfaceContainer: AppColors.surfaceSunken,
      onSurfaceVariant: AppColors.fgMuted,
      outline: AppColors.line,
      outlineVariant: AppColors.lineStrong,
      error: AppColors.danger,
      onError: Colors.white,
      errorContainer: AppColors.dangerSoft,
      onErrorContainer: AppColors.danger,
    );

    final textTheme = _textTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: textTheme,
      // 웹은 Pretendard를 쓰지만 앱에는 폰트 에셋을 아직 넣지 않았습니다.
      // 지정하지 않으면 각 플랫폼 기본 한글 폰트(Apple SD Gothic Neo / Noto Sans KR)를 씁니다.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.fg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.fg,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2,
          vertical: AppSpacing.md + 2,
        ),
        hintStyle: const TextStyle(color: AppColors.fgFaint, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.fgMuted, fontSize: 14),
        helperStyle: const TextStyle(color: AppColors.fgSubtle, fontSize: 12),
        errorStyle: const TextStyle(
          color: AppColors.danger,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        border: _fieldBorder(AppColors.line),
        enabledBorder: _fieldBorder(AppColors.line),
        focusedBorder: _fieldBorder(AppColors.brand500, width: 1.5),
        errorBorder: _fieldBorder(AppColors.danger),
        focusedErrorBorder: _fieldBorder(AppColors.danger, width: 1.5),
        disabledBorder: _fieldBorder(AppColors.line),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand500,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.ink300,
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.fg,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.line),
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand600,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.brand50,
        side: const BorderSide(color: AppColors.line),
        labelStyle: const TextStyle(
          color: AppColors.fgMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink800,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand500,
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme() {
    return const TextTheme(
      headlineSmall: TextStyle(
        color: AppColors.fg,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: TextStyle(
        color: AppColors.fg,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        color: AppColors.fg,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(color: AppColors.fg, fontSize: 15, height: 1.5),
      bodyMedium: TextStyle(color: AppColors.fgMuted, fontSize: 14, height: 1.5),
      bodySmall: TextStyle(color: AppColors.fgSubtle, fontSize: 12, height: 1.4),
      labelLarge: TextStyle(
        color: AppColors.fg,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      labelSmall: TextStyle(
        color: AppColors.fgSubtle,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
