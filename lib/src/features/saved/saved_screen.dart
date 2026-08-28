import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_callout.dart';
import '../auth/auth_controller.dart';
import 'save_place_button.dart';
import 'saved_controller.dart';
import 'saved_place.dart';

/// 저장 탭. 웹 `/account/saved`에 대응합니다.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final saved = Get.find<SavedController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('저장한 틈새'),
        actions: [
          Obx(() {
            if (!auth.isSignedIn || saved.count == 0) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Center(
                child: AppBadge('총 ${saved.count}개', tone: BadgeTone.caution),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (auth.isRestoring) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!auth.isSignedIn) {
          return const _SignedOutView();
        }

        if (saved.isLoading && saved.places.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: saved.load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (saved.errorMessage case final message?) ...[
                AppCallout(title: message, tone: CalloutTone.danger),
                const SizedBox(height: AppSpacing.md),
              ],
              if (saved.places.isEmpty && saved.errorMessage == null)
                const AppCallout(
                  title: '저장한 장소가 없습니다.',
                  description: '검색에서 마음에 든 쉼터를 저장해 보세요.',
                )
              else
                for (final place in saved.places)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _SavedPlaceCard(place: place),
                  ),
            ],
          ),
        );
      }),
    );
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const AppCallout(
          title: '로그인하면 저장한 틈새를 볼 수 있습니다.',
          description: '저장 목록은 기기가 아니라 계정에 남습니다.',
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => Get.toNamed(AppRoutes.login),
          child: const Text('로그인'),
        ),
      ],
    );
  }
}

class _SavedPlaceCard extends StatelessWidget {
  const _SavedPlaceCard({required this.place});

  final SavedPlace place;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.placeDetail(place.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (place.typeLabel.isNotEmpty)
                              AppBadge(place.typeLabel,
                                  tone: BadgeTone.outline),
                            if (place.savedAtLabel case final label?)
                              Text(label, style: textTheme.labelSmall),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(place.name, style: textTheme.titleMedium),
                        if (place.address.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            place.address,
                            style: textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SavePlaceButton(placeId: place.id, compact: true),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                [place.costLabel, place.spaceLabel, place.stayLabel]
                    .where((part) => part.isNotEmpty)
                    .join(' · '),
                style: textTheme.bodySmall,
              ),
              if (place.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final tag in place.tags.take(5)) AppBadge('#$tag'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
