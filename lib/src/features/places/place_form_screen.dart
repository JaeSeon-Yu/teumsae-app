import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_callout.dart';
import '../../widgets/app_section_card.dart';
import 'place_form.dart';
import 'place_form_controller.dart';
import 'place_map.dart';

/// 장소 등록·수정. 웹 `/places/new`와 `/places/[id]/edit`에 대응합니다.
///
/// 웹은 두 페이지가 `PlaceForm` 컴포넌트를 공유합니다. 앱도 화면 하나로 두고
/// 라우트 파라미터가 있으면 수정으로 씁니다.
class PlaceFormScreen extends GetView<PlaceFormController> {
  const PlaceFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(controller.title)),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return _FormBody(controller: controller);
      }),
    );
  }
}

class _FormBody extends StatefulWidget {
  const _FormBody({required this.controller});

  final PlaceFormController controller;

  @override
  State<_FormBody> createState() => _FormBodyState();
}

class _FormBodyState extends State<_FormBody> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _costMin;
  late final TextEditingController _costMax;
  late final TextEditingController _hours;
  late final TextEditingController _description;

  /// 주소는 핀을 옮기면 서버가 찾아 채워 줍니다. 그때 입력칸도 따라가야 합니다.
  StreamSubscription<PlaceFormValues>? _valuesSubscription;

  @override
  void initState() {
    super.initState();

    final values = widget.controller.values;
    _name = TextEditingController(text: values.name);
    _address = TextEditingController(text: values.address);
    _costMin = TextEditingController(text: values.estimatedCostMin);
    _costMax = TextEditingController(text: values.estimatedCostMax);
    _hours = TextEditingController(text: values.openingHoursCustom);
    _description = TextEditingController(text: values.description);

    _valuesSubscription = widget.controller.valueChanges.listen((next) {
      // 입력 중인 값을 덮어쓰지 않도록 다를 때만 맞춥니다.
      if (_address.text != next.address) {
        _address.text = next.address;
      }
    });
  }

  @override
  void dispose() {
    _valuesSubscription?.cancel();
    _name.dispose();
    _address.dispose();
    _costMin.dispose();
    _costMax.dispose();
    _hours.dispose();
    _description.dispose();
    super.dispose();
  }

  PlaceFormController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Obx(() {
          final message = controller.errorMessage;
          if (message == null) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCallout(title: message, tone: CalloutTone.danger),
          );
        }),
        AppSectionCard(
          title: '기본 정보',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _name,
                maxLength: PlaceFormValues.maxNameLength,
                decoration: const InputDecoration(
                  labelText: '장소 이름',
                  hintText: '예) 성북구립도서관',
                ),
                onChanged: (value) =>
                    controller.updateValues(controller.values.copyWith(name: value)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('장소 유형', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              Obx(
                () => Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final option in PlaceTypeOption.values)
                      ChoiceChip(
                        label: Text(option.label),
                        selected: controller.values.type == option,
                        onSelected: (_) => controller
                            .updateValues(controller.values.copyWith(type: option)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('테마', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              Obx(
                () => Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final option in PlaceThemeOption.values)
                      FilterChip(
                        label: Text(option.label),
                        selected: controller.values.themes.contains(option),
                        onSelected: (_) => controller.toggleTheme(option),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppSectionCard(
          title: '위치',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: Obx(
                    () => Get.find<PlaceMapBuilder>().picker(
                      lat: controller.values.lat,
                      lng: controller.values.lng,
                      onPicked: controller.movePin,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '지도를 눌러 위치를 정하세요.',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Obx(
                () => Text(
                  '${controller.values.lat.toStringAsFixed(6)}, '
                  '${controller.values.lng.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _address,
                maxLength: PlaceFormValues.maxAddressLength,
                decoration: InputDecoration(
                  labelText: '주소',
                  // 비워 두면 서버가 좌표로 찾아 채웁니다.
                  hintText: '비워 두면 좌표로 자동 입력됩니다',
                  suffixIcon: Obx(
                    () => controller.isResolvingAddress
                        ? const Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                onChanged: (value) => controller
                    .updateValues(controller.values.copyWith(address: value)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppSectionCard(
          title: '이용 정보',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('예상 비용대', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              Obx(
                () => Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final option in PriceLevelOption.values)
                      ChoiceChip(
                        label: Text(option.label),
                        selected: controller.values.priceLevel == option,
                        onSelected: (_) => controller.updateValues(
                          controller.values.copyWith(priceLevel: option),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _costMin,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: '최소 비용(원)'),
                      onChanged: (value) => controller.updateValues(
                        controller.values.copyWith(estimatedCostMin: value),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _costMax,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: '최대 비용(원)'),
                      onChanged: (value) => controller.updateValues(
                        controller.values.copyWith(estimatedCostMax: value),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Obx(
                () => _StayMinutesFields(
                  min: controller.values.stayMinutesMin,
                  max: controller.values.stayMinutesMax,
                  onChanged: (min, max) => controller.updateValues(
                    controller.values
                        .copyWith(stayMinutesMin: min, stayMinutesMax: max),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppSectionCard(
          title: '태그',
          child: Obx(() {
            if (controller.tagOptions.isEmpty) {
              return const AppCallout(
                title: '태그 목록을 불러오지 못했습니다.',
                description: '태그 없이도 등록할 수 있습니다.',
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '실내·실외와 편의시설은 태그로 정합니다.'
                  ' (${controller.values.tags.length}/'
                  '${PlaceFormValues.maxTagCount})',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final option in controller.tagOptions)
                      FilterChip(
                        label: Text(option.label),
                        selected: controller.values.tags.contains(option.label),
                        onSelected: (_) => controller.toggleTag(option.label),
                      ),
                  ],
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        AppSectionCard(
          title: '운영시간',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final mode in OpeningHoursMode.values)
                      ChoiceChip(
                        label: Text(mode.label),
                        selected: controller.values.openingHoursMode == mode,
                        onSelected: (_) => controller.updateValues(
                          controller.values.copyWith(openingHoursMode: mode),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Obx(() {
                switch (controller.values.openingHoursMode) {
                  case OpeningHoursMode.allDay:
                    return Text(
                      '24시간 운영으로 저장됩니다.',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  case OpeningHoursMode.range:
                    return _TimeRangeFields(
                      start: controller.values.openingHoursStart,
                      end: controller.values.openingHoursEnd,
                      onChanged: (start, end) => controller.updateValues(
                        controller.values.copyWith(
                          openingHoursStart: start,
                          openingHoursEnd: end,
                        ),
                      ),
                    );
                  case OpeningHoursMode.custom:
                    return TextField(
                      controller: _hours,
                      maxLength: PlaceFormValues.maxOpeningHoursLength,
                      decoration: const InputDecoration(
                        labelText: '운영시간',
                        hintText: '예) 평일 09:00-18:00 | 주말 휴무',
                      ),
                      onChanged: (value) => controller.updateValues(
                        controller.values.copyWith(openingHoursCustom: value),
                      ),
                    );
                }
              }),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppSectionCard(
          title: '설명',
          child: TextField(
            controller: _description,
            maxLines: 4,
            maxLength: PlaceFormValues.maxDescriptionLength,
            decoration: const InputDecoration(
              hintText: '이 장소를 쉼터로 쓸 때 알아 두면 좋은 점을 적어 주세요.',
            ),
            onChanged: (value) => controller
                .updateValues(controller.values.copyWith(description: value)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Obx(
          () => FilledButton(
            onPressed: controller.isSubmitting ? null : _submit,
            child: Text(
              controller.isSubmitting
                  ? '저장 중'
                  : (controller.isEditing ? '수정 저장' : '장소 등록'),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Future<void> _submit() async {
    final id = await controller.submit();
    if (id == null) {
      return;
    }

    // 저장한 장소를 바로 보여 줍니다. 폼으로 돌아오면 무엇이 저장됐는지 알 수 없습니다.
    Get.offNamed(AppRoutes.placeDetail(id));
  }
}

/// 체류 시간 입력. 서버가 1~1440분만 받습니다.
class _StayMinutesFields extends StatelessWidget {
  const _StayMinutesFields({
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int min;
  final int max;
  final void Function(int min, int max) onChanged;

  static const _options = <int>[15, 30, 60, 120, 240];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('머물 수 있는 시간', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _options.contains(min) ? min : _options.first,
                decoration: const InputDecoration(labelText: '최소'),
                items: [
                  for (final option in _options)
                    DropdownMenuItem(value: option, child: Text('$option분')),
                ],
                onChanged: (value) =>
                    onChanged(value ?? min, value != null && value > max ? value : max),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _options.contains(max) ? max : _options.last,
                decoration: const InputDecoration(labelText: '최대'),
                items: [
                  for (final option in _options)
                    DropdownMenuItem(value: option, child: Text('$option분')),
                ],
                onChanged: (value) => onChanged(min, value ?? max),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 시간 범위 입력. `HH:MM-HH:MM`으로 저장돼 서버·웹·앱이 모두 읽습니다.
class _TimeRangeFields extends StatelessWidget {
  const _TimeRangeFields({
    required this.start,
    required this.end,
    required this.onChanged,
  });

  final String start;
  final String end;
  final void Function(String start, String end) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TimeField(
            label: '여는 시간',
            value: start,
            onChanged: (value) => onChanged(value, end),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _TimeField(
            label: '닫는 시간',
            value: end,
            onChanged: (value) => onChanged(start, value),
          ),
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        final parts = value.split(':');
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.tryParse(parts.firstOrNull ?? '') ?? 9,
            minute: int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0,
          ),
        );
        if (picked == null) {
          return;
        }

        final hour = picked.hour.toString().padLeft(2, '0');
        final minute = picked.minute.toString().padLeft(2, '0');
        onChanged('$hour:$minute');
      },
      child: Text('$label $value'),
    );
  }
}
