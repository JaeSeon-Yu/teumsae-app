import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../auth/auth_controller.dart';

/// 설정 화면의 항목 하나(닉네임·비밀번호·탈퇴)의 상태.
///
/// 세 항목이 각자 진행 상태와 안내 문구를 가져야 해서 값 객체로 묶었습니다.
class SettingsFormStatus {
  const SettingsFormStatus({
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  const SettingsFormStatus.submitting() : this(isSubmitting: true);
  const SettingsFormStatus.failure(String message)
      : this(errorMessage: message);
  const SettingsFormStatus.success(String message)
      : this(successMessage: message);

  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
}

/// 계정 설정. 웹 `/account/settings`에 대응합니다.
///
/// 사용자 상태 변경은 [AuthController]가 하고, 이 컨트롤러는 화면 문구와 진행 상태만 봅니다.
class SettingsController extends GetxController {
  SettingsController(this._auth);

  final AuthController _auth;

  final _nickname = const SettingsFormStatus().obs;
  final _password = const SettingsFormStatus().obs;
  final _deleteAccount = const SettingsFormStatus().obs;

  SettingsFormStatus get nickname => _nickname.value;
  SettingsFormStatus get password => _password.value;
  SettingsFormStatus get deleteAccount => _deleteAccount.value;

  Future<void> submitNickname(String value) async {
    _nickname.value = const SettingsFormStatus.submitting();

    try {
      await _auth.updateNickname(value);
      _nickname.value = const SettingsFormStatus.success('닉네임을 저장했습니다.');
    } on ApiException catch (error) {
      _nickname.value = SettingsFormStatus.failure(error.message);
    } on Object {
      _nickname.value = const SettingsFormStatus.failure('닉네임을 저장하지 못했습니다.');
    }
  }

  /// 새 비밀번호 확인이 어긋나면 서버를 부르지 않습니다.
  Future<void> submitPassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      _password.value =
          const SettingsFormStatus.failure('새 비밀번호가 서로 일치하지 않습니다.');
      return;
    }

    _password.value = const SettingsFormStatus.submitting();

    try {
      await _auth.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _password.value = const SettingsFormStatus.success('비밀번호를 변경했습니다.');
    } on ApiException catch (error) {
      _password.value = SettingsFormStatus.failure(error.message);
    } on Object {
      _password.value = const SettingsFormStatus.failure('비밀번호를 변경하지 못했습니다.');
    }
  }

  /// 성공하면 로그아웃 상태가 됩니다. 화면 이동은 부르는 쪽에서 합니다.
  Future<bool> submitDeleteAccount(String password) async {
    _deleteAccount.value = const SettingsFormStatus.submitting();

    try {
      await _auth.deleteAccount(password);
      _deleteAccount.value = const SettingsFormStatus();
      return true;
    } on ApiException catch (error) {
      _deleteAccount.value = SettingsFormStatus.failure(error.message);
      return false;
    } on Object {
      _deleteAccount.value = const SettingsFormStatus.failure('회원 탈퇴를 처리하지 못했습니다.');
      return false;
    }
  }
}
