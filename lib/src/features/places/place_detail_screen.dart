import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_callout.dart';
import '../../widgets/app_section_card.dart';
import '../saved/save_place_button.dart';
import 'operating_hours.dart';
import 'place_detail.dart';
import 'place_detail_controller.dart';
import 'place_map.dart';
import 'place_reviews_section.dart';

/// 장소 상세. 웹 `/places/[id]`에 대응합니다.
///
/// 웹은 2단 레이아웃이지만 앱은 한 줄로 세웁니다. 중요한 것(이름·상태·비용)이
/// 위에 오고, 참고 정보(운영시간·위치·출처)가 아래로 갑니다.
class PlaceDetailScreen extends GetView<PlaceDetailController> {
  const PlaceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.place?.name ?? '장소 정보',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final message = controller.errorMessage;
        if (message != null) {
          return _ErrorView(message: message, onRetry: controller.load);
        }

        final place = controller.place;
        if (place == null) {
          return const SizedBox.shrink();
        }

        return _DetailBody(place: place);
      }),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.place});

  final PlaceDetail place;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _Header(place: place),
        if (place.userCreated) ...[
          const SizedBox(height: AppSpacing.md),
          AppCallout(
            title: '사용자 등록 장소',
            description: place.createdByUsername == null
                ? '사용자가 직접 추가한 장소입니다. 방문 전 위치와 운영 정보를 한 번 더 확인해 주세요.'
                : '${place.createdByUsername} 사용자가 직접 추가한 장소입니다.'
                    ' 방문 전 위치와 운영 정보를 한 번 더 확인해 주세요.',
            tone: CalloutTone.info,
          ),
        ],
        if (place.description != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppSectionCard(
            title: '장소 설명',
            child: Text(
              place.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        if (place.warnings.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _WarningList(warnings: place.warnings),
        ],
        const SizedBox(height: AppSpacing.md),
        _ScoreSection(place: place),
        const SizedBox(height: AppSpacing.md),
        _OperatingHoursSection(openingHoursText: place.openingHoursText),
        if (place.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppSectionCard(
            title: '태그',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final tag in place.tags) AppBadge('#$tag'),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        PlaceReviewsSection(place: place),
        const SizedBox(height: AppSpacing.md),
        _LocationSection(place: place),
        if (place.source != null || place.sourceUrl != null) ...[
          const SizedBox(height: AppSpacing.md),
          _SourceSection(source: place.source, sourceUrl: place.sourceUrl),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.place});

  final PlaceDetail place;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (place.typeLabel.isNotEmpty)
                  AppBadge(place.typeLabel, tone: BadgeTone.outline),
                if (place.openStatusLabel.isNotEmpty)
                  AppBadge(
                    place.openStatusLabel,
                    tone: _openStatusTone(place.openStatusLabel),
                  ),
                if (place.userCreated)
                  AppBadge(
                    place.createdByUsername == null
                        ? '사용자 추가'
                        : '${place.createdByUsername} 추가',
                    tone: BadgeTone.info,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(place.name, style: textTheme.headlineSmall),
            if (place.hasRating) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 18, color: AppColors.caution),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    place.averageRating!.toStringAsFixed(1),
                    style: textTheme.labelLarge,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '(${place.reviewCount}개의 후기)',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (place.address.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(place.address, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.lg),
            SavePlaceButton(placeId: place.id),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _InfoTile(label: '가격', value: place.costLabel),
                const SizedBox(width: AppSpacing.sm),
                _InfoTile(label: '공간', value: place.spaceLabel),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _InfoTile(label: '체류', value: place.stayLabel),
                const SizedBox(width: AppSpacing.sm),
                _InfoTile(
                  label: '유형',
                  value: place.typeLabel.isEmpty ? '정보 없음' : place.typeLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 서버 `OperatingStatus`의 라벨(영업중 / 휴게시간 / 영업종료) 기준.
  static BadgeTone _openStatusTone(String label) {
    if (label.contains('종료') || label.contains('휴무')) {
      return BadgeTone.neutral;
    }
    if (label.contains('휴게')) {
      return BadgeTone.caution;
    }
    return BadgeTone.positive;
  }
}

/// 웹 `InfoTile`. 값 하나를 라벨과 함께 보여 주는 작은 상자.
class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.fg,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreSection extends StatelessWidget {
  const _ScoreSection({required this.place});

  final PlaceDetail place;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: '편의 점수',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, score) in place.scores.labelled)
            _ScoreBar(label: label, score: score),
          const SizedBox(height: AppSpacing.md),
          const Text(
            '상황 적합도',
            style: TextStyle(
              color: AppColors.fg,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final (label, score) in place.weatherScores.labelled)
            _ScoreBar(label: label, score: score),
        ],
      ),
    );
  }
}

/// 0~5점을 막대로 보여 줍니다. 웹 `ScoreBar`와 같은 형태입니다.
class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                '$score/5',
                style: const TextStyle(
                  color: AppColors.fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 5,
              minHeight: 6,
              backgroundColor: AppColors.surfaceSunken,
              valueColor: const AlwaysStoppedAnimation(AppColors.brand500),
              // 낭독기가 "좌석 100%"처럼 읽습니다. 값은 위젯 기본 형식을 그대로 씁니다.
              semanticsLabel: label,
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatingHoursSection extends StatelessWidget {
  const _OperatingHoursSection({required this.openingHoursText});

  final String? openingHoursText;

  @override
  Widget build(BuildContext context) {
    final entries = OperatingHours.parse(openingHoursText);

    if (entries.isEmpty) {
      return AppSectionCard(
        title: '운영 정보',
        child: Text(
          '운영시간 정보가 아직 등록되지 않았습니다.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return AppSectionCard(
      title: '운영 정보',
      trailing: const AppBadge('월~일·공휴일', tone: BadgeTone.positive),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(color: AppColors.line),
                ),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppBadge(entry.days, tone: _badgeTone(entry.tone)),
                    if (entry.time.isNotEmpty)
                      Text(
                        entry.time,
                        style: const TextStyle(
                          color: AppColors.fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (entry.isClosed)
                      const AppBadge('정기 휴무', tone: BadgeTone.danger)
                    else if (entry.isAllDay && entry.time.isEmpty)
                      const AppBadge('24시간 운영', tone: BadgeTone.info),
                  ],
                ),
              ),
            ),
          Text(
            '※ 공휴일 및 명절에는 실제 운영 시간이 변경될 수 있으니 방문 전 한 번 더 확인해 주세요.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  static BadgeTone _badgeTone(OperatingHoursTone tone) => switch (tone) {
        OperatingHoursTone.neutral => BadgeTone.neutral,
        OperatingHoursTone.positive => BadgeTone.positive,
        OperatingHoursTone.caution => BadgeTone.caution,
        OperatingHoursTone.danger => BadgeTone.danger,
      };
}

class _WarningList extends StatelessWidget {
  const _WarningList({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.cautionSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.caution.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '가기 전 체크',
            style: TextStyle(
              color: AppColors.caution,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final warning in warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: AppSpacing.sm),
                    child: _Dot(color: AppColors.caution),
                  ),
                  Expanded(
                    child: Text(
                      warning,
                      style: const TextStyle(
                        color: AppColors.caution,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({required this.place});

  final PlaceDetail place;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppSectionCard(
      title: '위치',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (place.address.isNotEmpty)
            Text(place.address, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${place.lat.toStringAsFixed(6)}, ${place.lng.toStringAsFixed(6)}',
            style: textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.control),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Get.find<PlaceMapBuilder>().single(
                lat: place.lat,
                lng: place.lng,
                name: place.name,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            // 길찾기는 네이버 지도 앱이 훨씬 잘합니다. 앱이 없으면 브라우저가 받습니다.
            // 웹 상세 화면도 같은 주소로 보냅니다.
            onPressed: () => launchUrl(
              Uri.parse(
                'https://map.naver.com/p/search/'
                '${Uri.encodeComponent(place.name)}',
              ),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('네이버 지도에서 보기'),
          ),
        ],
      ),
    );
  }
}

class _SourceSection extends StatelessWidget {
  const _SourceSection({required this.source, required this.sourceUrl});

  final String? source;
  final String? sourceUrl;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Theme(
        // ExpansionTile의 기본 구분선을 없애 카드 테두리와 겹치지 않게 합니다.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text(
            '데이터 출처',
            style: TextStyle(
              color: AppColors.fg,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          shape: const Border(),
          collapsedShape: const Border(),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (source != null) Text(source!, style: textTheme.bodyMedium),
            if (sourceUrl != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(sourceUrl!, style: textTheme.labelSmall),
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
