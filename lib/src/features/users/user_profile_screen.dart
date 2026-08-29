import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_callout.dart';
import '../../widgets/app_section_card.dart';
import '../auth/auth_controller.dart';
import '../places/place_detail.dart';
import 'block_controller.dart';
import 'report_sheet.dart';
import 'user_profile.dart';
import 'user_profile_controller.dart';

/// 공개 프로필. 웹 `/users/[username]`에 대응합니다.
///
/// 로그인 없이도 볼 수 있습니다. 차단·신고는 로그인한 다른 사용자에게만 보입니다.
class UserProfileScreen extends GetView<UserProfileController> {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('@${controller.username}')),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final message = controller.errorMessage;
        if (message != null) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppCallout(title: message, tone: CalloutTone.danger),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: controller.load,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        final profile = controller.profile;
        if (profile == null) {
          return const SizedBox.shrink();
        }

        return _ProfileBody(profile: profile);
      }),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final auth = Get.find<AuthController>();
    final blocks = Get.find<BlockController>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.username, style: textTheme.titleLarge),
                if (profile.joinedLabel.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(profile.joinedLabel, style: textTheme.bodySmall),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _CountTile(
                      label: '등록한 틈새',
                      count: profile.registeredPlacesCount,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _CountTile(label: '작성한 후기', count: profile.reviewsCount),
                  ],
                ),
              ],
            ),
          ),
        ),
        // 내 프로필에는 차단·신고를 두지 않습니다. 서버도 자기 차단을 막습니다.
        Obx(() {
          if (!auth.isSignedIn || auth.user?.id == profile.id) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: _BlockReportActions(profile: profile, blocks: blocks),
          );
        }),
        const SizedBox(height: AppSpacing.md),
        AppSectionCard(
          title: '등록한 틈새 (${profile.registeredPlaces.length})',
          child: profile.registeredPlaces.isEmpty
              ? const AppCallout(title: '아직 등록한 장소가 없습니다.')
              : Column(
                  children: [
                    for (final place in profile.registeredPlaces)
                      _PlaceRow(place: place),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppSectionCard(
          title: '작성한 후기 (${profile.reviews.length})',
          child: profile.reviews.isEmpty
              ? const AppCallout(title: '아직 작성한 후기가 없습니다.')
              : Column(
                  children: [
                    for (final review in profile.reviews)
                      _ReviewRow(review: review),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _BlockReportActions extends StatelessWidget {
  const _BlockReportActions({required this.profile, required this.blocks});

  final UserProfile profile;
  final BlockController blocks;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isBlocked = blocks.isBlocked(profile.id);
      final isPending = blocks.isPending(profile.id);

      return Column(
        children: [
          if (isBlocked)
            AppCallout(
              title: '차단한 사용자입니다.',
              description: '이 사용자의 후기는 목록에서 보이지 않습니다.',
              tone: CalloutTone.info,
            ),
          if (isBlocked) const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: isPending
                ? null
                : () async {
                    if (isBlocked) {
                      await blocks.unblock(profile.id);
                    } else {
                      await _confirmBlock(context);
                    }
                    if (!context.mounted) {
                      return;
                    }
                    _showError(context, blocks);
                  },
            icon: Icon(
              isBlocked ? Icons.person_add_alt : Icons.block,
              size: 18,
            ),
            label: Text(isBlocked ? '차단 해제' : '이 사용자 차단'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () async {
              final reason = await ReportSheet.show(
                context,
                target: ReportTarget.user,
              );
              if (reason == null) {
                return;
              }

              final ok = await blocks.report(
                target: ReportTarget.user,
                targetId: profile.id,
                reason: reason,
              );
              if (!context.mounted) {
                return;
              }
              _showResult(context, blocks, ok: ok, done: '신고가 접수되었습니다.');
            },
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('이 사용자 신고'),
          ),
        ],
      );
    });
  }

  Future<void> _confirmBlock(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('사용자를 차단할까요?'),
        content: Text(
          '차단하면 ${profile.username} 사용자의 후기가 더 이상 보이지 않습니다.',
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

    if (confirmed ?? false) {
      await blocks.block(profile.id);
    }
  }
}

/// 실패만 스낵바로 알립니다. (저장·후기와 같은 규칙)
void _showError(BuildContext context, BlockController blocks) {
  final message = blocks.errorMessage;
  if (message == null || !context.mounted) {
    return;
  }

  blocks.clearError();
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

/// 신고는 화면이 바뀌지 않아 성공도 알려 줘야 합니다.
void _showResult(
  BuildContext context,
  BlockController blocks, {
  required bool ok,
  required String done,
}) {
  if (!ok) {
    _showError(context, blocks);
    return;
  }

  Get.showSnackbar(
    GetSnackBar(
      message: done,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadius.control,
    ),
  );
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelSmall),
        Text('$count', style: textTheme.titleMedium),
      ],
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.place});

  final PlaceDetail place;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(place.name),
      subtitle: Text(
        [place.typeLabel, place.address]
            .where((part) => part.isNotEmpty)
            .join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Get.toNamed(AppRoutes.placeDetail(place.id)),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.review});

  final UserReview review;

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
                child: InkWell(
                  onTap: () =>
                      Get.toNamed(AppRoutes.placeDetail(review.placeId)),
                  child: Text(
                    review.placeName,
                    style: textTheme.labelLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              AppBadge('${review.rating}점', tone: BadgeTone.outline),
              const SizedBox(width: AppSpacing.sm),
              Text(review.dateLabel, style: textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(review.comment, style: textTheme.bodyMedium),
          const Divider(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
