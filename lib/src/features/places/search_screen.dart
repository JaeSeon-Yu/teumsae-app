import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_callout.dart';
import '../../widgets/score_badge.dart';
import '../saved/save_place_button.dart';
import 'place_search_query.dart';
import 'place_summary.dart';
import 'places_controller.dart';
import 'search_filters_sheet.dart';

/// 검색 탭. 검색은 로그인 없이도 됩니다(서버에서 GET /api/places/** 공개).
class SearchScreen extends GetView<PlacesController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('틈새')),
      body: Column(
        children: [
          Obx(
            () => _ThemeTabs(
              selected: controller.query.theme,
              onSelected: controller.changeTheme,
            ),
          ),
          Obx(
            () => _FilterBar(
              query: controller.query,
              isLocating: controller.isLocating,
              usingCurrentLocation: controller.usingCurrentLocation,
              onToggleCurrentLocation: () async {
                if (controller.usingCurrentLocation) {
                  await controller.useDefaultLocation();
                  return;
                }

                await controller.useCurrentLocation();

                // 성공은 결과 목록이 바뀌는 것으로 보입니다. 실패만 따로 알려 줍니다.
                final message = controller.locationError;
                if (message == null) {
                  return;
                }

                controller.clearLocationError();
                Get.showSnackbar(
                  GetSnackBar(
                    message: message,
                    duration: const Duration(seconds: 3),
                    snackPosition: SnackPosition.BOTTOM,
                    margin: const EdgeInsets.all(AppSpacing.md),
                    borderRadius: AppRadius.control,
                  ),
                );
              },
              onOpenFilters: () async {
                final applied = await SearchFiltersSheet.show(
                  context,
                  query: controller.query,
                );
                if (applied != null) {
                  await controller.applyFilters(applied);
                }
              },
              onSortChanged: controller.changeSort,
              onToggleOpenOnly: controller.toggleOpenOnly,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final message = controller.errorMessage;
              if (message != null) {
                return _ErrorView(message: message, onRetry: controller.search);
              }

              return _ResultList(
                places: controller.places,
                onRefresh: controller.search,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ThemeTabs extends StatelessWidget {
  const _ThemeTabs({required this.selected, required this.onSelected});

  final SearchTheme selected;
  final ValueChanged<SearchTheme> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            for (final theme in SearchTheme.values)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: Text(theme.label),
                  selected: selected == theme,
                  onSelected: (_) => onSelected(theme),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 조건 버튼 · 정렬 · 영업중 토글. 웹은 사이드 패널과 지도 위 토글로 나뉘어 있지만
/// 앱은 좁은 화면이라 한 줄에 모읍니다.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.query,
    required this.isLocating,
    required this.usingCurrentLocation,
    required this.onToggleCurrentLocation,
    required this.onOpenFilters,
    required this.onSortChanged,
    required this.onToggleOpenOnly,
  });

  final PlaceSearchQuery query;
  final bool isLocating;
  final bool usingCurrentLocation;
  final VoidCallback onToggleCurrentLocation;
  final VoidCallback onOpenFilters;
  final ValueChanged<SearchSort> onSortChanged;
  final VoidCallback onToggleOpenOnly;

  @override
  Widget build(BuildContext context) {
    final activeCount = query.activeFilterCount;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          spacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: onOpenFilters,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
              ),
              icon: const Icon(Icons.tune, size: 18),
              label: Text(activeCount == 0 ? '조건' : '조건 $activeCount'),
            ),
            // 조건 시트 밖에 둡니다. 좌표가 바뀌면 결과가 전부 달라져서
            // 다른 조건과 함께 초안으로 묶으면 무엇이 바뀐 건지 알기 어렵습니다.
            FilterChip(
              label: const Text('내 위치'),
              selected: usingCurrentLocation,
              // 조회 중에는 잠급니다. 연달아 누르면 요청이 겹칩니다.
              onSelected: isLocating ? null : (_) => onToggleCurrentLocation(),
              avatar: isLocating
                  ? const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 18),
            ),
            FilterChip(
              label: const Text('지금 운영중'),
              selected: query.openOnly,
              onSelected: (_) => onToggleOpenOnly(),
            ),
            for (final sort in SearchSort.values)
              ChoiceChip(
                label: Text(sort.label),
                selected: query.sort == sort,
                onSelected: (_) => onSortChanged(sort),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({required this.places, required this.onRefresh});

  final List<PlaceSummary> places;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            AppCallout(
              title: '조건에 맞는 틈새가 없습니다.',
              description: '반경을 넓히거나 다른 테마로 바꿔 보세요.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: places.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => _PlaceCard(place: places[index]),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place});

  final PlaceSummary place;

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
                    child: Text(place.name, style: textTheme.titleMedium),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ScoreBadge(
                    score: place.restScore,
                    label: place.scoreLabel,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                [
                  place.typeLabel,
                  place.distanceLabel,
                  place.priceLabel,
                  if (place.openStatusLabel != null) place.openStatusLabel!,
                ].where((part) => part.isNotEmpty).join(' · '),
                style: textTheme.bodySmall,
              ),
              if (place.address.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(place.address, style: textTheme.bodyMedium),
              ],
              if (place.reasons.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final reason in place.reasons.take(3))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius:
                              BorderRadius.circular(AppRadius.control),
                        ),
                        child: Text(reason, style: textTheme.labelSmall),
                      ),
                  ],
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final tag in place.tags.take(3)) AppBadge('#$tag'),
                      ],
                    ),
                  ),
                  SavePlaceButton(placeId: place.id, compact: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppCallout(title: message, tone: CalloutTone.danger),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
