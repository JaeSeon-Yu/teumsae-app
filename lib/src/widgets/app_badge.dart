import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// 웹 `Badge`의 톤을 그대로 옮긴 값입니다.
enum BadgeTone { neutral, outline, brand, positive, caution, danger, info }

/// 짧은 상태 문구용 배지. 태그·역할·영업 상태에 같은 형태를 씁니다.
class AppBadge extends StatelessWidget {
  const AppBadge(this.label, {this.tone = BadgeTone.neutral, super.key});

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (tone) {
      BadgeTone.neutral => (AppColors.surfaceSunken, AppColors.fgMuted, null),
      BadgeTone.outline => (AppColors.surface, AppColors.fgMuted, AppColors.line),
      BadgeTone.brand => (AppColors.brand600, Colors.white, null),
      BadgeTone.positive => (
          AppColors.positiveSoft,
          AppColors.positive,
          AppColors.brand200,
        ),
      BadgeTone.caution => (
          AppColors.cautionSoft,
          AppColors.caution,
          AppColors.caution.withValues(alpha: 0.2),
        ),
      BadgeTone.danger => (
          AppColors.dangerSoft,
          AppColors.danger,
          AppColors.danger.withValues(alpha: 0.2),
        ),
      BadgeTone.info => (
          AppColors.infoSoft,
          AppColors.info,
          AppColors.info.withValues(alpha: 0.2),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }
}
