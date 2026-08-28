import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

    // 로그인 화면은 항상 셸 위에 쌓이므로, 되돌아가면 보고 있던 탭이 유지됩니다.
    if (_controller.isSignedIn) {
      if (Get.previousRoute == AppRoutes.home) {
        Get.back();
      } else {
        Get.offAllNamed(AppRoutes.home);
      }
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: isSubmitting ? null : _submit,
                        child: Text(
                          isSubmitting
                              ? '처리 중...'
                              : _isSignup
                                  ? '가입하고 시작하기'
                                  : '로그인',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: isSubmitting
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

  /// maxLength는 입력 제한에만 쓰고 "0/20" 카운터는 숨깁니다.
  static Widget? _hideCounter(
    BuildContext context, {
    required int currentLength,
    required int? maxLength,
    required bool isFocused,
  }) =>
      null;
}
