import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'place_search_query.dart';

/// 검색 조건 바텀시트. 웹 `SearchFilters` 패널에 대응합니다.
///
/// 고르는 동안에는 초안만 바꾸고, "조건 적용"을 눌렀을 때 [PlaceSearchQuery]를 돌려줍니다.
/// 취소하면 `null`입니다.
class SearchFiltersSheet extends StatefulWidget {
  const SearchFiltersSheet({required this.query, super.key});

  final PlaceSearchQuery query;

  /// 시트를 띄우고 적용된 조건을 받습니다.
  static Future<PlaceSearchQuery?> show(
    BuildContext context, {
    required PlaceSearchQuery query,
  }) {
    return showModalBottomSheet<PlaceSearchQuery>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SearchFiltersSheet(query: query),
    );
  }

  @override
  State<SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<SearchFiltersSheet> {
  late PlaceSearchQuery _draft = widget.query;

  void _update(PlaceSearchQuery next) => setState(() => _draft = next);

  void _toggleNeed(SearchNeed need) {
    final needs = {..._draft.needs};
    if (!needs.remove(need)) {
      needs.add(need);
    }
    _update(_draft.copyWith(needs: needs));
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _draft.activeFilterCount;

    return SafeArea(
      child: Padding(
        // 화면 높이의 대부분을 쓰되, 위쪽은 원래 목록이 보이게 남겨 둡니다.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(
                activeCount: activeCount,
                onReset: activeCount == 0
                    ? null
                    : () => _update(_draft.resetFilters()),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _FilterGroup(
                      label: '남은 시간',
                      children: [
                        for (final minutes in PlaceSearchQuery.stayMinutesOptions)
                          ChoiceChip(
                            label: Text(_stayLabel(minutes)),
                            selected: _draft.stayMinutes == minutes,
                            onSelected: (_) =>
                                _update(_draft.copyWith(stayMinutes: minutes)),
                          ),
                      ],
                    ),
                    _FilterGroup(
                      label: '반경',
                      children: [
                        for (final radius in PlaceSearchQuery.radiusOptions)
                          ChoiceChip(
                            label: Text(_radiusLabel(radius)),
                            selected: _draft.radius == radius,
                            onSelected: (_) =>
                                _update(_draft.copyWith(radius: radius)),
                          ),
                      ],
                    ),
                    _FilterGroup(
                      label: '실내 / 실외',
                      children: [
                        for (final space in SearchSpace.values)
                          ChoiceChip(
                            label: Text(space.label),
                            selected: _draft.space == space,
                            onSelected: (_) =>
                                _update(_draft.copyWith(space: space)),
                          ),
                      ],
                    ),
                    _FilterGroup(
                      label: '예산',
                      children: [
                        for (final budget in SearchBudget.values)
                          ChoiceChip(
                            label: Text(budget.label),
                            selected: _draft.budget == budget,
                            onSelected: (_) =>
                                _update(_draft.copyWith(budget: budget)),
                          ),
                      ],
                    ),
                    _FilterGroup(
                      label: '필요 시설 (모두 만족)',
                      children: [
                        for (final need in SearchNeed.values)
                          FilterChip(
                            label: Text(need.label),
                            selected: _draft.needs.contains(need),
                            onSelected: (_) => _toggleNeed(need),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_draft),
                  child: const Text('조건 적용'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _stayLabel(int minutes) => switch (minutes) {
        0 => '상관없음',
        60 => '1시간',
        120 => '2시간 이상',
        final value => '$value분',
      };

  static String _radiusLabel(int meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)}km' : '${meters}m';
}

class _Header extends StatelessWidget {
  const _Header({required this.activeCount, required this.onReset});

  final int activeCount;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Text('검색 조건', style: Theme.of(context).textTheme.titleMedium),
          if (activeCount > 0) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.brand50,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$activeCount',
                style: const TextStyle(
                  color: AppColors.brand700,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (onReset != null)
            TextButton(onPressed: onReset, child: const Text('초기화')),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: '검색 조건 닫기',
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: children,
          ),
        ],
      ),
    );
  }
}
