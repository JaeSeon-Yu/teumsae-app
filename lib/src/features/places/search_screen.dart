import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_callout.dart';
import '../auth/auth_controller.dart';
import 'place_summary.dart';
import 'places_controller.dart';

/// 홈 화면. 검색은 로그인 없이도 됩니다(서버에서 GET /api/places/** 공개).
class SearchScreen extends GetView<PlacesController> {
  const SearchScreen({super.key});

  static const themes = <(String, String)>[
    ('REST', '쉼터'),
    ('SHOPPING', '쇼핑'),
    ('PLAY', '놀거리'),
    ('TOILET', '화장실'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('틈새'),
        actions: const [_AccountAction()],
      ),
      body: Column(
        children: [
          Obx(
            () => _ThemeTabs(
              selected: controller.query.theme,
              onSelected: controller.changeTheme,
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

/// 앱바 우측: 로그인 전에는 로그인 버튼, 후에는 닉네임 + 로그아웃 메뉴.
class _AccountAction extends StatelessWidget {
  const _AccountAction();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Obx(() {
      final user = auth.user;

      if (user == null) {
        return TextButton(
          onPressed: () => Get.toNamed(AppRoutes.login),
          child: const Text('로그인'),
        );
      }

      return PopupMenuButton<String>(
        tooltip: '계정 메뉴',
        onSelected: (value) {
          if (value == 'logout') {
            auth.logout();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'logout', child: Text('로그아웃')),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Text(user.nickname, style: Theme.of(context).textTheme.labelLarge),
              const Icon(Icons.expand_more, color: AppColors.fgSubtle),
            ],
          ),
        ),
      );
    });
  }
}

class _ThemeTabs extends StatelessWidget {
  const _ThemeTabs({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          for (final (value, label) in SearchScreen.themes)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(label),
                selected: selected == value,
                onSelected: (_) => onSelected(value),
              ),
            ),
        ],
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brand50,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: Text(
                    '${place.restScore}점',
                    style: const TextStyle(
                      color: AppColors.brand700,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                        borderRadius: BorderRadius.circular(AppRadius.control),
                      ),
                      child: Text(reason, style: textTheme.labelSmall),
                    ),
                ],
              ),
            ],
          ],
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
