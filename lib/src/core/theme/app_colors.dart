import 'package:flutter/material.dart';

/// teumsae-web `app/globals.css`의 디자인 토큰을 옮긴 값입니다.
/// 웹과 앱의 색이 갈리지 않도록, 값을 바꿀 때는 양쪽을 함께 수정해 주세요.
abstract final class AppColors {
  // --- Brand: 틈새 그린 (휴식/여유) ---
  static const brand50 = Color(0xFFEEF9F3);
  static const brand100 = Color(0xFFD5F0E3);
  static const brand200 = Color(0xFFADE0C9);
  static const brand300 = Color(0xFF7BCAA8);
  static const brand400 = Color(0xFF46AD85);
  static const brand500 = Color(0xFF1F9268);
  static const brand600 = Color(0xFF0F7A55);
  static const brand700 = Color(0xFF0C6145);
  static const brand800 = Color(0xFF0B4D38);
  static const brand900 = Color(0xFF093C2D);

  // --- Ink: 텍스트/보더/서피스 중립 스케일 ---
  static const ink50 = Color(0xFFF7F8F7);
  static const ink100 = Color(0xFFEEF0EF);
  static const ink200 = Color(0xFFE0E3E1);
  static const ink300 = Color(0xFFC7CCC9);
  static const ink400 = Color(0xFF98A09C);
  static const ink500 = Color(0xFF6E7672);
  static const ink600 = Color(0xFF515855);
  static const ink700 = Color(0xFF3B4240);
  static const ink800 = Color(0xFF262B29);
  static const ink900 = Color(0xFF141816);

  // --- Semantic surface / text / line ---
  static const canvas = Color(0xFFF1F4F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF7F8F7);
  static const surfaceSunken = Color(0xFFEEF0EF);
  static const line = Color(0xFFE0E3E1);
  static const lineStrong = Color(0xFFC7CCC9);
  static const fg = Color(0xFF141816);
  static const fgMuted = Color(0xFF515855);
  static const fgSubtle = Color(0xFF6E7672);
  static const fgFaint = Color(0xFF98A09C);

  // --- Status ---
  static const positive = Color(0xFF0F7A55);
  static const positiveSoft = Color(0xFFEEF9F3);
  static const caution = Color(0xFFB45309);
  static const cautionSoft = Color(0xFFFFF7ED);
  static const danger = Color(0xFFBE123C);
  static const dangerSoft = Color(0xFFFFF1F3);
  static const info = Color(0xFF1D63B8);
  static const infoSoft = Color(0xFFEFF6FF);

  // --- Category accents (테마 탭/핀) ---
  static const catRest = Color(0xFF0F7A55);
  static const catShopping = Color(0xFFB45309);
  static const catPlay = Color(0xFF4F46B8);
  static const catToilet = Color(0xFF0E7490);
}

/// 웹의 `--radius-*` 4단계 스케일. 이 밖의 값은 쓰지 않습니다.
abstract final class AppRadius {
  /// chip, badge, small button
  static const control = 10.0;

  /// input, button
  static const field = 14.0;

  /// card, panel
  static const card = 20.0;

  /// bottom sheet, hero
  static const sheet = 28.0;
}

/// 웹의 `--space-*` 대응. 4px 그리드를 유지합니다.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}
