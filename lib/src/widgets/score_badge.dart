import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum ScoreBadgeSize { small, large }

/// 점수 배지. 웹 `ScoreBadge`의 색 구간(85 / 70 / 50)을 그대로 옮겼습니다.
///
/// [label]에는 서버가 준 `scoreLabel`을 그대로 넣습니다.
/// (웹은 목록에서만 테마별 문구로 갈아 끼우지만, 앱은 목록·상세 모두 서버 값을 씁니다.)
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({
    required this.score,
    required this.label,
    this.size = ScoreBadgeSize.small,
    super.key,
  });

  final int score;
  final String label;
  final ScoreBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = _tone();
    final isLarge = size == ScoreBadgeSize.large;

    return Container(
      constraints: BoxConstraints(minWidth: isLarge ? 76 : 56),
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? AppSpacing.md : AppSpacing.sm,
        vertical: isLarge ? AppSpacing.sm : AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score',
            style: TextStyle(
              color: foreground,
              fontSize: isLarge ? 24 : 18,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// 색은 4단계로만 구분합니다.
  (Color, Color, Color) _tone() {
    if (score >= 85) {
      return (AppColors.brand50, AppColors.brand700, AppColors.brand200);
    }
    if (score >= 70) {
      return (
        AppColors.infoSoft,
        AppColors.info,
        AppColors.info.withValues(alpha: 0.2),
      );
    }
    if (score >= 50) {
      return (
        AppColors.cautionSoft,
        AppColors.caution,
        AppColors.caution.withValues(alpha: 0.2),
      );
    }
    return (AppColors.surfaceMuted, AppColors.fgSubtle, AppColors.line);
  }
}
