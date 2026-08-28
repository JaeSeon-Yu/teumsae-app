import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_callout.dart';
import '../../widgets/app_section_card.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_validators.dart';
import 'settings_controller.dart';

/// 계정 설정. 웹 `/account/settings`에 대응합니다.
///
/// 항목마다 폼을 따로 두는 이유는 서버 엔드포인트가 셋으로 나뉘어 있고
/// 하나가 실패해도 다른 항목의 입력이 날아가면 안 되기 때문입니다.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = Get.find<SettingsController>();
  final _auth = Get.find<AuthController>();

  final _nicknameFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _deleteFormKey = GlobalKey<FormState>();

  late final TextEditingController _nickname =
      TextEditingController(text: _auth.user?.nickname ?? '');
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _deletePassword = TextEditingController();

  @override
  void dispose() {
    _nickname.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    _deletePassword.dispose();
    super.dispose();
  }

  Future<void> _submitNickname() async {
    if (!(_nicknameFormKey.currentState?.validate() ?? false)) return;

    await _controller.submitNickname(_nickname.text);
  }

  Future<void> _submitPassword() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;

    await _controller.submitPassword(
      currentPassword: _currentPassword.text,
      newPassword: _newPassword.text,
      confirmPassword: _confirmPassword.text,
    );

    if (_controller.password.successMessage != null) {
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
    }
  }

  Future<void> _submitDeleteAccount() async {
    if (!(_deleteFormKey.currentState?.validate() ?? false)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('탈퇴 후에는 이 계정으로 다시 로그인할 수 없습니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('탈퇴하기'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (await _controller.submitDeleteAccount(_deletePassword.text)) {
      // 탈퇴하면 로그인 상태가 아니므로 설정 화면에 남아 있을 수 없습니다.
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('계정 및 보안 설정')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppSectionCard(
            title: '닉네임 변경',
            child: Form(
              key: _nicknameFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Obx(() {
                    final username = _auth.user?.username ?? '';
                    return Text(
                      '리뷰와 등록한 장소에 보이는 이름입니다. (아이디: @$username)',
                      style: textTheme.bodySmall,
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _nickname,
                    decoration: const InputDecoration(labelText: '새 닉네임'),
                    maxLength: AuthValidators.nicknameMaxLength,
                    buildCounter: _hideCounter,
                    textInputAction: TextInputAction.done,
                    validator: AuthValidators.validateNicknameChange,
                  ),
                  Obx(
                    () => _FormFeedback(
                      status: _controller.nickname,
                      submitLabel: '닉네임 저장',
                      submittingLabel: '저장 중...',
                      onSubmit: _submitNickname,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Obx(() {
            // 소셜 로그인 계정은 비밀번호가 없어 서버가 항상 실패로 응답합니다.
            if (_auth.user?.provider != 'LOCAL') {
              return const AppSectionCard(
                title: '비밀번호 변경',
                child: AppCallout(
                  title: '아이디로 가입한 계정만 비밀번호를 바꿀 수 있습니다.',
                  tone: CalloutTone.info,
                ),
              );
            }

            return AppSectionCard(
              title: '비밀번호 변경',
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _currentPassword,
                      decoration: const InputDecoration(labelText: '현재 비밀번호'),
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      validator: AuthValidators.validateLoginPassword,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _newPassword,
                      decoration: const InputDecoration(
                        labelText: '새 비밀번호',
                        helperText: AuthValidators.passwordHint,
                      ),
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      maxLength: AuthValidators.passwordMaxLength,
                      buildCounter: _hideCounter,
                      validator: AuthValidators.validatePassword,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _confirmPassword,
                      decoration:
                          const InputDecoration(labelText: '새 비밀번호 확인'),
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      maxLength: AuthValidators.passwordMaxLength,
                      buildCounter: _hideCounter,
                      validator: AuthValidators.validatePassword,
                    ),
                    Obx(
                      () => _FormFeedback(
                        status: _controller.password,
                        submitLabel: '비밀번호 변경',
                        submittingLabel: '변경 중...',
                        onSubmit: _submitPassword,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.md),
          AppSectionCard(
            title: '회원 탈퇴',
            child: Form(
              key: _deleteFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '탈퇴하면 이 계정으로 다시 로그인할 수 없습니다.'
                    ' 작성한 후기와 저장 목록은 운영 지침에 따라 처리됩니다.',
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _deletePassword,
                    decoration: const InputDecoration(labelText: '비밀번호 재확인'),
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    validator: AuthValidators.validateLoginPassword,
                  ),
                  Obx(
                    () => _FormFeedback(
                      status: _controller.deleteAccount,
                      submitLabel: '회원 탈퇴',
                      submittingLabel: '탈퇴 중...',
                      onSubmit: _submitDeleteAccount,
                      isDanger: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  /// maxLength는 입력 제한에만 쓰고 "0/50" 카운터는 숨깁니다.
  static Widget? _hideCounter(
    BuildContext context, {
    required int currentLength,
    required int? maxLength,
    required bool isFocused,
  }) =>
      null;
}

/// 항목별 안내 문구 + 제출 버튼. 세 항목이 같은 형태를 씁니다.
class _FormFeedback extends StatelessWidget {
  const _FormFeedback({
    required this.status,
    required this.submitLabel,
    required this.submittingLabel,
    required this.onSubmit,
    this.isDanger = false,
  });

  final SettingsFormStatus status;
  final String submitLabel;
  final String submittingLabel;
  final Future<void> Function() onSubmit;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status.errorMessage case final message?) ...[
          const SizedBox(height: AppSpacing.md),
          AppCallout(title: message, tone: CalloutTone.danger),
        ],
        if (status.successMessage case final message?) ...[
          const SizedBox(height: AppSpacing.md),
          AppCallout(title: message, tone: CalloutTone.info),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: status.isSubmitting ? null : onSubmit,
          style: isDanger
              ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
              : null,
          child: Text(status.isSubmitting ? submittingLabel : submitLabel),
        ),
      ],
    );
  }
}
