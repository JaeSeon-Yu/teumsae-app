import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_callout.dart';
import '../../widgets/app_section_card.dart';
import '../auth/auth_controller.dart';
import '../users/block_controller.dart';
import '../users/report_sheet.dart';
import '../users/user_profile.dart';
import 'place_detail.dart';
import 'place_detail_controller.dart';
import 'place_review.dart';

/// 방문자 후기. 웹 `PlaceReviewsSection`에 대응합니다.
class PlaceReviewsSection extends StatefulWidget {
  const PlaceReviewsSection({required this.place, super.key});

  final PlaceDetail place;

  @override
  State<PlaceReviewsSection> createState() => _PlaceReviewsSectionState();
}

class _PlaceReviewsSectionState extends State<PlaceReviewsSection> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlaceDetailController>();
    final auth = Get.find<AuthController>();
    final blocks = Get.find<BlockController>();

    return AppSectionCard(
      title: '방문자 후기',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RatingSummary(place: widget.place),
          const SizedBox(height: AppSpacing.md),
          Obx(() {
            final message = controller.reviewError;
            if (message == null) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCallout(title: message, tone: CalloutTone.danger),
            );
          }),
          Obx(
            () => auth.isSignedIn
                ? _ReviewForm(
                    controller: controller,
                    commentController: _commentController,
                  )
                : const _SignInPrompt(),
          ),
          const SizedBox(height: AppSpacing.md),
          Obx(() {
            // 차단한 사용자의 후기는 목록에서 감춥니다. 서버는 그대로 주므로
            // 앱에서 걸러 냅니다. (웹도 차단 직후 목록에서 지웁니다)
            final reviews = controller.reviews
                .where((review) => !blocks.isBlocked(review.userId))
                .toList(growable: false);
            if (reviews.isEmpty) {
              return const AppCallout(
                title: '아직 후기가 없습니다.',
                description: '첫 번째 후기를 남겨 보세요.',
              );
            }

            return Column(
              children: [
                for (final review in reviews)
                  _ReviewTile(
                    review: review,
                    controller: controller,
                    blocks: blocks,
                    canDelete: _canDelete(auth, review),
                    canModerate: auth.isSignedIn &&
                        auth.user?.id != review.userId,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// 서버도 같은 조건으로 막습니다. (`PlaceReviewController.deleteReview`)
  /// 지울 수 없는 버튼을 보여 주고 403을 받게 하지 않습니다.
  bool _canDelete(AuthController auth, PlaceReview review) {
    final user = auth.user;
    if (user == null) {
      return false;
    }
    return user.id == review.userId || user.isAdmin;
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.place});

  final PlaceDetail place;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final average = place.averageRating;

    return Row(
      children: [
        _Stars(
          // 후기가 없으면 서버가 평균을 null로 줍니다. 이때는 빈 별로 둡니다.
          filled: average == null ? 0 : average.round(),
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          place.hasRating ? '${average!.toStringAsFixed(1)} / 5.0' : '평점 없음',
          style: textTheme.titleSmall,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text('(${place.reviewCount}개)', style: textTheme.labelSmall),
      ],
    );
  }
}

/// 별 표시. 점수를 읽어 주는 라벨을 함께 둡니다.
class _Stars extends StatelessWidget {
  const _Stars({required this.filled, this.size = 16});

  final int filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$filled점',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var star = 1; star <= ReviewValidators.maxRating; star++)
            Icon(
              star <= filled ? Icons.star : Icons.star_border,
              size: size,
              color: AppColors.caution,
              // 별 하나하나를 읽어 주면 "별 별 별..."이 되므로 묶어서 읽힙니다.
              semanticLabel: '',
            ),
        ],
      ),
    );
  }
}

class _ReviewForm extends StatelessWidget {
  const _ReviewForm({
    required this.controller,
    required this.commentController,
  });

  final PlaceDetailController controller;
  final TextEditingController commentController;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('내 평점', style: textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Obx(
            () => Row(
              children: [
                for (var star = 1;
                    star <= ReviewValidators.maxRating;
                    star++)
                  IconButton(
                    onPressed: () => controller.changeRating(star),
                    tooltip: '$star점',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      star <= controller.rating
                          ? Icons.star
                          : Icons.star_border,
                      color: AppColors.caution,
                    ),
                  ),
                const SizedBox(width: AppSpacing.xs),
                Text('${controller.rating}점', style: textTheme.labelLarge),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: commentController,
            maxLines: 3,
            maxLength: ReviewValidators.maxCommentLength,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: '후기 내용',
              hintText: '장소에 대한 후기를 자유롭게 남겨 보세요.',
            ),
          ),
          // 테마가 FilledButton을 가로 전체로 만듭니다. 오른쪽 정렬로 두면
          // 무한 너비를 요구해 레이아웃이 깨집니다.
          Obx(
            () => FilledButton(
              onPressed: controller.isSubmittingReview
                  ? null
                  : () async {
                      if (await controller.submitReview(
                        commentController.text,
                      )) {
                        commentController.clear();
                      }
                    },
              child: Text(
                controller.isSubmittingReview ? '등록 중' : '후기 등록',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context) {
    // 테마가 OutlinedButton을 가로 전체로 만들어서(`Size.fromHeight`)
    // 문구 옆에 나란히 둘 수 없습니다. 아래로 내려 붙입니다.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '로그인하면 후기와 평점을 남길 수 있습니다.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        // 서버에 401을 만들지 않고 미리 로그인으로 보냅니다. (저장 버튼과 같은 규칙)
        OutlinedButton(
          onPressed: () => Get.toNamed(AppRoutes.login),
          child: const Text('로그인'),
        ),
      ],
    );
  }
}

/// 남의 후기에 붙는 신고·차단. 웹은 링크 두 개로 두지만 앱은 좁아서 메뉴로 모읍니다.
class _ModerationMenu extends StatelessWidget {
  const _ModerationMenu({required this.review, required this.blocks});

  final PlaceReview review;
  final BlockController blocks;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '신고 · 차단',
      icon: const Icon(Icons.more_vert, size: 18),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'report', child: Text('신고')),
        PopupMenuItem(value: 'block', child: Text('차단')),
      ],
      onSelected: (value) async {
        if (value == 'report') {
          await _report(context);
          return;
        }
        await _confirmBlock(context);
      },
    );
  }

  Future<void> _report(BuildContext context) async {
    final reason = await ReportSheet.show(
      context,
      target: ReportTarget.review,
    );
    if (reason == null || !context.mounted) {
      return;
    }

    final ok = await blocks.report(
      target: ReportTarget.review,
      targetId: review.id,
      reason: reason,
    );
    if (!context.mounted) {
      return;
    }

    // 신고는 화면이 바뀌지 않아 성공도 알려 줘야 합니다.
    _snack(ok ? '신고가 접수되었습니다.' : (blocks.errorMessage ?? '신고를 접수하지 못했습니다.'));
    blocks.clearError();
  }

  Future<void> _confirmBlock(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('사용자를 차단할까요?'),
        content: Text(
          '차단하면 ${review.username} 사용자의 후기가 더 이상 보이지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('차단'),
          ),
        ],
      ),
    );

    if (!(confirmed ?? false)) {
      return;
    }

    // 성공하면 목록에서 사라지는 것으로 보입니다. 실패만 알립니다.
    if (!await blocks.block(review.userId)) {
      _snack(blocks.errorMessage ?? '차단하지 못했습니다.');
      blocks.clearError();
    }
  }

  void _snack(String message) {
    Get.showSnackbar(
      GetSnackBar(
        message: message,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppRadius.control,
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.review,
    required this.controller,
    required this.blocks,
    required this.canDelete,
    required this.canModerate,
  });

  final PlaceReview review;
  final PlaceDetailController controller;
  final BlockController blocks;
  final bool canDelete;

  /// 남의 후기를 로그인 상태로 보고 있는지. 신고·차단을 보일지 정합니다.
  final bool canModerate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: InkWell(
                        onTap: review.username.isEmpty
                            ? null
                            : () => Get.toNamed(
                                  AppRoutes.userProfile(review.username),
                                ),
                        child: Text(
                          review.username,
                          style: textTheme.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _Stars(filled: review.rating),
                  ],
                ),
              ),
              Text(review.dateLabel, style: textTheme.labelSmall),
              if (canDelete)
                Obx(
                  () => TextButton(
                    onPressed: controller.deletingReviewId != null
                        ? null
                        : () => _confirmDelete(context),
                    child: Text(
                      controller.deletingReviewId == review.id ? '삭제 중' : '삭제',
                    ),
                  ),
                )
              else if (canModerate)
                // 신고·차단을 버튼 두 개로 두면 후기 한 줄이 버튼으로 가득 찹니다.
                _ModerationMenu(review: review, blocks: blocks),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(review.comment, style: textTheme.bodyMedium),
          const Divider(height: AppSpacing.lg),
        ],
      ),
    );
  }

  /// 삭제는 되돌릴 수 없어 한 번 더 묻습니다. (웹도 `confirm`을 씁니다)
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('후기를 삭제할까요?'),
        content: const Text('삭제한 후기는 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          // 다이얼로그 버튼은 TextButton으로 둡니다. FilledButton은 테마가
          // 가로 전체로 만들어서 액션 줄에 들어가지 못합니다. (설정 화면과 같은 방식)
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await controller.deleteReview(review.id);
    }
  }
}
