import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../auth/auth_controller.dart';
import 'saved_controller.dart';

/// 장소 저장 토글. 웹 `SavePlaceButton`에 대응합니다.
///
/// 로그인하지 않은 상태에서 누르면 서버에 401을 만들지 않고 바로 로그인 화면으로 보냅니다.
class SavePlaceButton extends StatelessWidget {
  const SavePlaceButton({required this.placeId, this.compact = false, super.key});

  final int placeId;

  /// 목록 카드처럼 좁은 자리에서는 아이콘만 씁니다.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final saved = Get.find<SavedController>();
    final auth = Get.find<AuthController>();

    return Obx(() {
      final isSaved = saved.isSaved(placeId);
      final isPending = saved.isPending(placeId);

      Future<void> onPressed() async {
        if (!auth.isSignedIn) {
          Get.toNamed(AppRoutes.login);
          return;
        }

        if (await saved.toggle(placeId)) {
          return;
        }

        // 성공은 버튼 모양이 바뀌는 것으로 충분히 보입니다.
        // 실패만 따로 알려 줍니다.
        Get.showSnackbar(
          GetSnackBar(
            message: saved.errorMessage ?? '저장 상태를 변경하지 못했습니다.',
            duration: const Duration(seconds: 3),
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(AppSpacing.md),
            borderRadius: AppRadius.control,
          ),
        );
      }

      if (compact) {
        return IconButton(
          onPressed: isPending ? null : onPressed,
          isSelected: isSaved,
          tooltip: isSaved ? '저장 취소' : '저장',
          icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
        );
      }

      final label = isPending
          ? '처리 중'
          : isSaved
              ? '저장됨'
              : '저장';

      return isSaved
          ? FilledButton.icon(
              onPressed: isPending ? null : onPressed,
              icon: const Icon(Icons.bookmark, size: 18),
              label: Text(label),
            )
          : OutlinedButton.icon(
              onPressed: isPending ? null : onPressed,
              icon: const Icon(Icons.bookmark_border, size: 18),
              label: Text(label),
            );
    });
  }
}
