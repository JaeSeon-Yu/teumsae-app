import 'dart:async';

import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_user.dart';
import 'user_profile.dart';
import 'users_repository.dart';

/// 차단 상태의 단일 출처.
///
/// 후기 목록과 공개 프로필이 모두 이 컨트롤러를 봅니다. 화면마다 따로 들고 있으면
/// 한 화면에서 차단한 사용자가 다른 화면에는 그대로 보입니다.
/// 그래서 [InitialBinding]에서 `permanent`로 등록합니다.
///
/// 로그인하지 않으면 목록은 항상 비어 있습니다. (서버가 401을 주는 엔드포인트)
class BlockController extends GetxController {
  BlockController({
    required UsersRepository repository,
    required AuthController auth,
  })  : _repository = repository,
        _auth = auth;

  final UsersRepository _repository;
  final AuthController _auth;

  final _blockedIds = <int>{}.obs;
  final _pendingIds = <int>{}.obs;
  final _errorMessage = RxnString();

  StreamSubscription<AuthUser?>? _authSubscription;

  String? get errorMessage => _errorMessage.value;

  bool isBlocked(int userId) => _blockedIds.contains(userId);

  /// 차단·해제 요청이 오가는 중인지. 버튼을 잠그는 데 씁니다.
  bool isPending(int userId) => _pendingIds.contains(userId);

  @override
  void onInit() {
    super.onInit();

    if (_auth.isSignedIn) {
      load();
    }

    // 앱 시작 직후의 자동 로그인도 이 스트림으로 들어옵니다.
    _authSubscription = _auth.userChanges.listen((user) {
      if (user == null) {
        _blockedIds.clear();
        _pendingIds.clear();
        _errorMessage.value = null;
      } else {
        load();
      }
    });
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  Future<void> load() async {
    try {
      _blockedIds.assignAll(await _repository.blockedUserIds());
    } on Object {
      // 차단 목록을 못 받아도 나머지 화면은 그대로 써야 합니다.
      _blockedIds.clear();
    }
  }

  /// 차단하면 `true`. 실패하면 [errorMessage]를 채우고 `false`.
  Future<bool> block(int userId) => _toggle(userId, blocking: true);

  Future<bool> unblock(int userId) => _toggle(userId, blocking: false);

  Future<bool> _toggle(int userId, {required bool blocking}) async {
    if (_pendingIds.contains(userId)) {
      return false;
    }

    _pendingIds.add(userId);
    _errorMessage.value = null;

    try {
      if (blocking) {
        await _repository.block(userId);
        _blockedIds.add(userId);
      } else {
        await _repository.unblock(userId);
        _blockedIds.remove(userId);
      }
      return true;
    } on ApiException catch (error) {
      _errorMessage.value = error.message;
      return false;
    } on Object {
      _errorMessage.value = blocking ? '차단하지 못했습니다.' : '차단을 해제하지 못했습니다.';
      return false;
    } finally {
      _pendingIds.remove(userId);
    }
  }

  /// 신고. 성공하면 `true`, 실패하면 [errorMessage]를 채우고 `false`.
  ///
  /// 차단과 함께 두는 이유는 둘 다 후기 목록에서 같은 자리에 쓰이고
  /// 상태를 나눠 봐야 할 이유가 없기 때문입니다.
  Future<bool> report({
    required ReportTarget target,
    required int targetId,
    required String reason,
  }) async {
    final invalid = ReportValidators.validateReason(reason);
    if (invalid != null) {
      _errorMessage.value = invalid;
      return false;
    }

    _errorMessage.value = null;

    try {
      await _repository.report(
        target: target,
        targetId: targetId,
        reason: reason,
      );
      return true;
    } on ApiException catch (error) {
      _errorMessage.value = error.message;
      return false;
    } on Object {
      _errorMessage.value = '신고를 접수하지 못했습니다.';
      return false;
    }
  }

  void clearError() => _errorMessage.value = null;
}
