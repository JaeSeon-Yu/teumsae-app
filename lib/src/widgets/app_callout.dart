import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum CalloutTone { info, caution, danger, neutral }

/// 웹 `Callout` 컴포넌트와 같은 역할. 안내·에러를 한 형태로 통일합니다.
class AppCallout extends StatelessWidget {
  const AppCallout({
    required this.title,
    this.description,
    this.tone = CalloutTone.neutral,
    super.key,
  });

  final String title;
  final String? description;
  final CalloutTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      CalloutTone.info => (AppColors.infoSoft, AppColors.info),
      CalloutTone.caution => (AppColors.cautionSoft, AppColors.caution),
      CalloutTone.danger => (AppColors.dangerSoft, AppColors.danger),
      CalloutTone.neutral => (AppColors.surfaceMuted, AppColors.fgMuted),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: foreground.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: foreground,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description!,
              style: TextStyle(
                color: foreground.withValues(alpha: 0.85),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
