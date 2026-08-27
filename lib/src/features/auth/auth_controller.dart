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
