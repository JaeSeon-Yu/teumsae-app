import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_callout.dart';
import 'my_places_controller.dart';
import 'place_detail.dart';

/// 내가 등록한 장소. 웹 `/account/places`에 대응합니다.
class MyPlacesScreen extends GetView<MyPlacesController> {
  const MyPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내가 등록한 장소'),
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.placeNew),
            tooltip: '장소 등록',
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final message = controller.errorMessage;
        if (message != null && controller.places.isEmpty) {
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

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // 삭제가 실패했을 때는 목록을 남겨 두고 위에만 알립니다.
              if (message != null) ...[
                AppCallout(title: message, tone: CalloutTone.danger),
                const SizedBox(height: AppSpacing.md),
              ],
              if (controller.places.isEmpty)
                const AppCallout(
                  title: '아직 등록한 장소가 없습니다.',
                  description: '알고 있는 쉼터를 등록하면 다른 사람도 찾을 수 있습니다.',
                )
              else
                for (final place in controller.places) ...[
                  _MyPlaceCard(place: place, controller: controller),
                  const SizedBox(height: AppSpacing.md),
                ],
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.placeNew),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('새 장소 등록'),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MyPlaceCard extends StatelessWidget {
  const _MyPlaceCard({required this.place, required this.controller});

  final PlaceDetail place;
  final MyPlacesController controller;

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
                children: [
                  Expanded(
                    child: Text(place.name, style: textTheme.titleMedium),
                  ),
                  if (place.typeLabel.isNotEmpty)
                    AppBadge(place.typeLabel, tone: BadgeTone.outline),
                ],
              ),
              if (place.address.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(place.address, style: textTheme.bodySmall),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                [
                  place.priceLabel,
                  place.spaceLabel,
                  place.stayLabel,
                ].where((part) => part.isNotEmpty).join(' · '),
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () =>
                          Get.toNamed(AppRoutes.placeEdit(place.id)),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('수정'),
                    ),
                  ),
                  Expanded(
                    child: Obx(
                      () => TextButton.icon(
                        onPressed: controller.deletingId != null
                            ? null
                            : () => _confirmDelete(context),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(
                          controller.deletingId == place.id ? '삭제 중' : '삭제',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 삭제는 되돌릴 수 없어 한 번 더 묻습니다. (후기 삭제와 같은 방식)
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('장소를 삭제할까요?'),
        content: Text('${place.name}을(를) 삭제하면 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await controller.delete(place.id);
    }
  }
}
