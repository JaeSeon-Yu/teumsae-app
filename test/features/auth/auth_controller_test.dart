import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/core/network/api_client.dart';
import 'package:teumsae_app/src/core/network/api_exception.dart';
import 'package:teumsae_app/src/core/network/auth_tokens.dart';
import 'package:teumsae_app/src/core/storage/token_store.dart';
import 'package:teumsae_app/src/features/auth/auth_controller.dart';
import 'package:teumsae_app/src/features/auth/auth_repository.dart';
import 'package:teumsae_app/src/features/auth/auth_user.dart';

final _user = const AuthUser(
  id: 1,
  username: 'teumsae_user',
  nickname: '틈새유저',
  role: 'USER',
  provider: 'LOCAL',
);

AuthSession _session() => AuthSession(
      user: _user,
      tokens: AuthTokens(
        tokenType: 'Bearer',
        accessToken: 'access',
        accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
        refreshToken: 'refresh',
      ),
    );

/// 서버 호출 없이 컨트롤러의 상태 전이만 확인하기 위한 대역.
class _StubAuthRepository extends AuthRepository {
  _StubAuthRepository({this.error, this.restored})
      : super(
          apiClient: ApiClient(tokenStore: InMemoryTokenStore()),
          tokenStore: InMemoryTokenStore(),
        );

  /// 지정하면 login/signup이 이 예외를 던집니다.
  final Object? error;

  /// restoreSession이 돌려줄 세션.
  final AuthSession? restored;

  bool logoutCalled = false;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    if (error != null) throw error!;
    return _session();
  }

  @override
  Future<AuthSession> signup({
    required String username,
    required String password,
    String? nickname,
  }) async {
    if (error != null) throw error!;
    return _session();
  }

  @override
  Future<AuthSession?> restoreSession() async => restored;

  @override
  Future<void> logout() async => logoutCalled = true;
}

void main() {
  group('login', () {
    test('성공하면 사용자를 채우고 에러를 비운다', () async {
      final controller = AuthController(_StubAuthRepository());

      await controller.login(username: 'teumsae_user', password: 'password');

      expect(controller.isSignedIn, isTrue);
      expect(controller.user?.nickname, '틈새유저');
      expect(controller.errorMessage, isNull);
      expect(controller.isSubmitting, isFalse);
    });

    test('서버 에러 메시지를 그대로 노출하고 로그아웃 상태를 유지한다', () async {
      final controller = AuthController(
        _StubAuthRepository(
          error: const ApiException(
            statusCode: 401,
            message: '아이디 또는 비밀번호가 올바르지 않습니다.',
          ),
        ),
      );

      await controller.login(username: 'teumsae_user', password: 'wrong');

      expect(controller.isSignedIn, isFalse);
      expect(controller.errorMessage, '아이디 또는 비밀번호가 올바르지 않습니다.');
      expect(controller.isSubmitting, isFalse);
    });

    test('예상 못 한 예외도 화면용 문구로 바꾼다', () async {
      final controller = AuthController(
        _StubAuthRepository(error: StateError('boom')),
      );

      await controller.login(username: 'teumsae_user', password: 'password');

      expect(controller.errorMessage, '요청을 처리할 수 없습니다. 잠시 후 다시 시도해 주세요.');
    });
  });

  group('signup', () {
    test('성공하면 바로 로그인 상태가 된다', () async {
      final controller = AuthController(_StubAuthRepository());

      await controller.signup(
        username: 'teumsae_user',
        password: 'password',
        nickname: '틈새유저',
      );

      expect(controller.isSignedIn, isTrue);
    });
  });

  group('restoreSession', () {
    test('저장된 세션이 있으면 자동 로그인된다', () async {
      final controller = AuthController(
        _StubAuthRepository(restored: _session()),
      );

      await controller.restoreSession();

      expect(controller.isSignedIn, isTrue);
      expect(controller.isRestoring, isFalse);
    });

    test('저장된 세션이 없으면 로그아웃 상태로 시작한다', () async {
      final controller = AuthController(_StubAuthRepository());

      await controller.restoreSession();

      expect(controller.isSignedIn, isFalse);
      expect(controller.isRestoring, isFalse);
    });
  });

  test('logout은 리포지토리를 호출하고 사용자를 비운다', () async {
    final repository = _StubAuthRepository();
    final controller = AuthController(repository);
    await controller.login(username: 'teumsae_user', password: 'password');

    await controller.logout();

    expect(repository.logoutCalled, isTrue);
    expect(controller.isSignedIn, isFalse);
  });

  test('handleSessionExpired는 로그아웃 상태로 되돌리고 안내를 남긴다', () async {
    final controller = AuthController(_StubAuthRepository());
    await controller.login(username: 'teumsae_user', password: 'password');

    controller.handleSessionExpired();

    expect(controller.isSignedIn, isFalse);
    expect(controller.errorMessage, '세션이 만료되었습니다. 다시 로그인해 주세요.');

    controller.clearError();
    expect(controller.errorMessage, isNull);
  });
}
