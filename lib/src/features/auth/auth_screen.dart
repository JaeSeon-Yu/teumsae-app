import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/auth/social_sign_in.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_callout.dart';
import 'auth_controller.dart';
import 'auth_validators.dart';

enum AuthMode { login, signup }

/// 로그인 화면과 회원가입 화면은 입력 항목만 다르므로 한 위젯으로 처리합니다.
class AuthScreen extends StatefulWidget {
  const AuthScreen({required this.mode, super.key});

  final AuthMode mode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _controller = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _obscurePassword = true;

  bool get _isSignup => widget.mode == AuthMode.signup;

  @override
  void initState() {
    super.initState();
    // 이전 화면에서 남은 에러 문구를 지우고 시작합니다.
    _controller.clearError();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final username = _usernameController.text;
    final password = _passwordController.text;

    if (_isSignup) {
      await _controller.signup(
        username: username,
        password: password,
        nickname: _nicknameController.text,
      );
    } else {
      await _controller.login(username: username, password: password);
    }

    _leaveIfSignedIn();
  }

  /// 소셜 로그인은 입력 검증 없이 바로 시작합니다.
  ///
  /// 회원가입 화면에서 닉네임만 적어 뒀다면 그 값을 넘깁니다. 아이디·비밀번호는
  /// 소셜 계정에 필요 없으므로 폼 검증을 돌리지 않습니다.
  Future<void> _signInWithSocial(SocialProvider provider) async {
    await _controller.signInWithSocial(
      provider,
      nickname: _isSignup ? _nicknameController.text : null,
    );

    _leaveIfSignedIn();
  }

  void _leaveIfSignedIn() {
    // 로그인 화면은 항상 셸 위에 쌓이므로, 되돌아가면 보고 있던 탭이 유지됩니다.
    if (!_controller.isSignedIn) {
      return;
    }

    if (Get.previousRoute == AppRoutes.home) {
      Get.back();
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSignup ? '회원가입' : '로그인')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isSignup ? '틈새 계정 만들기' : '다시 틈새 찾기',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _isSignup
                      ? '계정을 만들면 마음에 든 쉼터를 저장하고 직접 등록할 수 있습니다.'
                      : '저장한 틈새와 등록한 장소를 이어서 확인해 보세요.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),

                // 소셜 로그인은 폼 위에 둡니다. 웹과 같은 순서입니다.
                // Firebase 설정이 없으면 통째로 사라집니다.
                _socialSection(context),

                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: '아이디',
                    hintText: 'teumsae_user',
                    helperText: _isSignup ? AuthValidators.usernameHint : null,
                  ),
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  maxLength: AuthValidators.usernameMaxLength,
                  buildCounter: _hideCounter,
                  validator: AuthValidators.validateUsername,
                ),
                const SizedBox(height: AppSpacing.lg),

                if (_isSignup) ...[
                  TextFormField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: '닉네임 (선택)',
                      hintText: '서비스에서 보일 이름',
                      helperText: '비워 두면 아이디가 표시됩니다.',
                    ),
                    textInputAction: TextInputAction.next,
                    maxLength: AuthValidators.nicknameMaxLength,
                    buildCounter: _hideCounter,
                    validator: AuthValidators.validateNickname,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    helperText: _isSignup ? AuthValidators.passwordHint : null,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() {
                        _obscurePassword = !_obscurePassword;
                      }),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.fgSubtle,
                      ),
                      tooltip: _obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                    ),
                  ),
                  obscureText: _obscurePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  maxLength: AuthValidators.passwordMaxLength,
                  buildCounter: _hideCounter,
                  validator: _isSignup
                      ? AuthValidators.validatePassword
                      : AuthValidators.validateLoginPassword,
                  onFieldSubmitted: (_) =>
                      _controller.isSubmitting ? null : _submit(),
                ),

                Obx(() {
                  final message = _controller.errorMessage;
                  if (message == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: AppCallout(title: message, tone: CalloutTone.danger),
                  );
                }),

                const SizedBox(height: AppSpacing.xl),
                Obx(() {
                  final isSubmitting = _controller.isSubmitting;
                  final isBusy =
                      isSubmitting || _controller.pendingSocial != null;
                  // 소셜 버튼이 함께 보일 때만 "이메일로"를 붙입니다. (웹과 같은 문구)
                  // 버튼이 하나뿐이면 굳이 수단을 밝힐 이유가 없습니다.
                  final withSocial = _controller.isSocialAvailable;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: isBusy ? null : _submit,
                        child: Text(
                          isSubmitting
                              ? '처리 중...'
                              : _isSignup
                                  ? (withSocial
                                      ? '이메일로 가입하고 시작하기'
                                      : '가입하고 시작하기')
                                  : (withSocial ? '이메일로 로그인' : '로그인'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: isBusy
                            ? null
                            : () => Get.offNamed(
                                  _isSignup
                                      ? AppRoutes.login
                                      : AppRoutes.signup,
                                ),
                        child: Text(
                          _isSignup ? '이미 계정이 있어요' : '계정이 없어요, 회원가입',
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 소셜 로그인 버튼과 구분선. Firebase가 준비되지 않았으면 아무것도 그리지 않습니다.
  ///
  /// 눌러도 실패만 하는 버튼을 보여 주는 대신 감춥니다. 아이디·비밀번호 로그인이
  /// 그대로 있어서 사용자가 막히지는 않습니다.
  ///
  /// 준비 여부는 앱이 켜져 있는 동안 바뀌지 않으므로 `Obx`로 감싸지 않습니다.
  /// (감싸면 관찰할 값이 없는 `Obx`가 되어 GetX가 잘못된 사용으로 봅니다)
  Widget _socialSection(BuildContext context) {
    if (!_controller.isSocialAvailable) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          final pending = _controller.pendingSocial;
          final isBusy = _controller.isSubmitting || pending != null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                onPressed: isBusy
                    ? null
                    : () => _signInWithSocial(SocialProvider.google),
                child: Text(
                  pending == SocialProvider.google
                      ? '구글 연동 중...'
                      : 'Google 계정으로 계속하기',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: isBusy
                    ? null
                    : () => _signInWithSocial(SocialProvider.apple),
                style: FilledButton.styleFrom(
                  // 애플 지침이 정한 검정 버튼. 브랜드 초록과 섞으면 심사에서 걸립니다.
                  backgroundColor: AppColors.ink900,
                  foregroundColor: AppColors.surface,
                ),
                child: Text(
                  pending == SocialProvider.apple ? '애플 연동 중...' : 'Apple로 계속하기',
                ),
              ),
            ],
          );
        }),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Row(
            children: [
              Expanded(child: Divider(color: AppColors.line)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  '또는 이메일로 계속',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.fgSubtle,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.line)),
            ],
          ),
        ),
      ],
    );
  }

  /// maxLength는 입력 제한에만 쓰고 "0/20" 카운터는 숨깁니다.
  static Widget? _hideCounter(
    BuildContext context, {
    required int currentLength,
    required int? maxLength,
    required bool isFocused,
  }) =>
      null;
}
