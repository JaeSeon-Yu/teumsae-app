import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import 'auth_repository.dart';
import 'auth_user.dart';

/// 로그인 상태를 앱 전체가 공유합니다. [InitialBinding]에서 `permanent`로 등록합니다.
///
/// 화면은 `Obx(() => ...)` 안에서 [user], [isSubmitting], [errorMessage]를 읽습니다.
class AuthController extends GetxController {
  AuthController(this._repository);

  final AuthRepository _repository;

  final _user = Rxn<AuthUser>();
  final _isRestoring = true.obs;
  final _isSubmitting = false.obs;
  final _errorMessage = RxnString();

  /// 로그인한 사용자. 로그아웃 상태면 `null`.
  AuthUser? get user => _user.value;
  bool get isSignedIn => _user.value != null;

  /// 앱 시작 직후 저장된 토큰으로 자동 로그인을 시도하는 동안 `true`.
  bool get isRestoring => _isRestoring.value;

  bool get isSubmitting => _isSubmitting.value;

  /// 서버 메시지는 이미 한글이므로 화면에서 그대로 보여주면 됩니다.
  String? get errorMessage => _errorMessage.value;

  /// 로그인·로그아웃 시점을 다른 컨트롤러가 알 수 있게 여는 통로.
  ///
  /// 예) 저장 목록은 로그인하면 불러오고 로그아웃하면 비워야 합니다.
  /// `Rx` 자체를 공개하면 밖에서 값을 바꿀 수 있어 읽기 전용 스트림만 냅니다.
  Stream<AuthUser?> get userChanges => _user.stream;

  @override
  void onInit() {
    super.onInit();
    restoreSession();
  }

  /// 저장된 refresh token으로 세션을 복구합니다. 실패하면 로그아웃 상태로 둡니다.
  Future<void> restoreSession() async {
    _isRestoring.value = true;
    try {
      final session = await _repository.restoreSession();
      _user.value = session?.user;
    } finally {
      _isRestoring.value = false;
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) {
    return _submit(
      () => _repository.login(username: username, password: password),
    );
  }

  Future<void> signup({
    required String username,
    required String password,
    String? nickname,
  }) {
    return _submit(
      () => _repository.signup(
        username: username,
        password: password,
        nickname: nickname,
      ),
    );
  }

  Future<void> logout() async {
    _isSubmitting.value = true;
    try {
      await _repository.logout();
      _user.value = null;
      _errorMessage.value = null;
    } finally {
      _isSubmitting.value = false;
    }
  }

  // --- 설정 화면용. 실패는 예외로 던집니다. ---
  // 로그인 화면과 [errorMessage]를 공유하면 설정 화면의 항목별 안내를 구분할 수 없어서
  // 문구는 부르는 쪽(`SettingsController`)이 정합니다.

  /// 성공하면 [user]의 닉네임이 갱신됩니다.
  Future<void> updateNickname(String nickname) async {
    _user.value = await _repository.updateNickname(nickname);
  }

  /// 비밀번호를 바꾸고 새 토큰으로 세션을 이어 갑니다.
  ///
  /// 서버가 비밀번호 변경 시 기존 세션을 모두 폐기하기 때문에
  /// 재로그인까지 성공해야 로그인 상태가 유지됩니다.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final username = _user.value?.username;
    if (username == null) {
      throw StateError('로그인 상태가 아닙니다.');
    }

    final session = await _repository.changePassword(
      username: username,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    _user.value = session.user;
  }

  /// 계정을 탈퇴하고 로그아웃 상태로 되돌립니다.
  Future<void> deleteAccount(String password) async {
    await _repository.deleteAccount(password);
    _user.value = null;
    _errorMessage.value = null;
  }

  /// refresh까지 실패했을 때 [ApiClient]가 호출합니다.
  /// 토큰은 이미 지워진 상태이므로 화면 상태만 로그아웃으로 되돌립니다.
  void handleSessionExpired() {
    _user.value = null;
    _errorMessage.value = '세션이 만료되었습니다. 다시 로그인해 주세요.';
  }

  void clearError() => _errorMessage.value = null;

  /// 실패를 [errorMessage]로 옮겨 화면이 사라지지 않게 합니다.
  Future<void> _submit(Future<AuthSession> Function() action) async {
    _isSubmitting.value = true;
    _errorMessage.value = null;

    try {
      final session = await action();
      _user.value = session.user;
    } on ApiException catch (error) {
      _errorMessage.value = error.message;
    } on Object {
      _errorMessage.value = '요청을 처리할 수 없습니다. 잠시 후 다시 시도해 주세요.';
    } finally {
      _isSubmitting.value = false;
    }
  }
}
