import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'user_profile.dart';

/// 신고 사유를 받는 시트.
///
/// 웹은 `prompt()`로 한 줄 받지만 앱에는 그런 것이 없어서 시트로 만듭니다.
/// 자주 쓰는 사유를 눌러 채울 수 있게 해 두면 입력이 짧아집니다.
class ReportSheet extends StatefulWidget {
  const ReportSheet({required this.target, super.key});

  final ReportTarget target;

  /// 신고 사유를 돌려줍니다. 취소하면 `null`.
  static Future<String?> show(
    BuildContext context, {
    required ReportTarget target,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReportSheet(target: target),
    );
  }

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final _reason = TextEditingController();
  String? _error;

  /// 웹 `prompt` 안내에 적힌 예시와 같습니다.
  static const _presets = <String>['스팸', '욕설', '부적절한 내용', '허위 정보'];

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        // 키보드가 올라와도 입력칸이 가리지 않게 합니다.
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.target.label} 신고', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '관리자가 확인한 뒤 조치합니다.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final preset in _presets)
                ActionChip(
                  label: Text(preset),
                  onPressed: () => setState(() {
                    _reason.text = preset;
                    _error = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _reason,
            maxLength: ReportValidators.maxReasonLength,
            decoration: InputDecoration(
              labelText: '신고 사유',
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) {
                setState(() => _error = null);
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: () {
              final invalid = ReportValidators.validateReason(_reason.text);
              if (invalid != null) {
                setState(() => _error = invalid);
                return;
              }
              Navigator.of(context).pop(_reason.text.trim());
            },
            child: const Text('신고하기'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
}
