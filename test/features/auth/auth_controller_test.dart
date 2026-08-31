import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/core/auth/social_sign_in.dart';
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

  /// socialLogin에 넘어온 값. 서버에 무엇을 보냈는지 확인할 때 씁니다.
  String? socialIdToken;
  String? socialNickname;

  @override
  Future<AuthSession> socialLogin({
    required String idToken,
    String? nickname,
  }) async {
    socialIdToken = idToken;
    socialNickname = nickname;
    if (error != null) throw error!;
    return _session();
  }
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

  group('signInWithSocial', () {
    test('Firebase idToken을 서버로 넘기고 로그인 상태가 된다', () async {
      final repository = _StubAuthRepository();
      final social = FakeSocialSignIn(
        credential: const SocialCredential(
          idToken: 'firebase-id-token',
          displayName: '구글유저',
        ),
      );
      final controller = AuthController(repository, socialSignIn: social);

      await controller.signInWithSocial(SocialProvider.google);

      expect(social.requestedProvider, SocialProvider.google);
      expect(repository.socialIdToken, 'firebase-id-token');
      expect(controller.isSignedIn, isTrue);
      expect(controller.errorMessage, isNull);
      expect(controller.pendingSocial, isNull);
    });

    test('적어 둔 닉네임이 소셜 계정 이름보다 앞선다', () async {
      final repository = _StubAuthRepository();
      final controller = AuthController(
        repository,
        socialSignIn: FakeSocialSignIn(
          credential: const SocialCredential(
            idToken: 'token',
            displayName: '구글유저',
          ),
        ),
      );

      await controller.signInWithSocial(
        SocialProvider.google,
        nickname: '내가정한닉',
      );

      expect(repository.socialNickname, '내가정한닉');
    });

    test('닉네임을 비워 두면 소셜 계정 이름을 쓴다', () async {
      final repository = _StubAuthRepository();
      final controller = AuthController(
        repository,
        socialSignIn: FakeSocialSignIn(
          credential: const SocialCredential(
            idToken: 'token',
            displayName: '구글유저',
          ),
        ),
      );

      await controller.signInWithSocial(SocialProvider.google, nickname: '   ');

      expect(repository.socialNickname, '구글유저');
    });

    test('사용자가 취소하면 서버를 부르지 않고 에러도 남기지 않는다', () async {
      final repository = _StubAuthRepository();
      // credential이 null이면 취소한 것으로 봅니다.
      final controller = AuthController(
        repository,
        socialSignIn: FakeSocialSignIn(),
      );

      await controller.signInWithSocial(SocialProvider.apple);

      expect(repository.socialIdToken, isNull);
      expect(controller.isSignedIn, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.pendingSocial, isNull);
    });

    test('소셜 SDK 실패 문구를 그대로 노출한다', () async {
      final controller = AuthController(
        _StubAuthRepository(),
        socialSignIn: FakeSocialSignIn(
          error: const SocialSignInException('구글 로그인 설정이 올바르지 않습니다.'),
        ),
      );

      await controller.signInWithSocial(SocialProvider.google);

      expect(controller.errorMessage, '구글 로그인 설정이 올바르지 않습니다.');
      expect(controller.isSignedIn, isFalse);
      expect(controller.pendingSocial, isNull);
    });

    test('서버가 거절하면 서버 메시지를 보여 준다', () async {
      final controller = AuthController(
        _StubAuthRepository(
          error: const ApiException(
            statusCode: 403,
            message: '이 계정은 사용할 수 없습니다.',
          ),
        ),
        socialSignIn: FakeSocialSignIn(
          credential: const SocialCredential(idToken: 'token'),
        ),
      );

      await controller.signInWithSocial(SocialProvider.google);

      expect(controller.errorMessage, '이 계정은 사용할 수 없습니다.');
      expect(controller.isSignedIn, isFalse);
    });

    test('진행 중에는 어떤 수단을 누른 상태인지 알린다', () async {
      final controller = AuthController(
        _StubAuthRepository(),
        socialSignIn: FakeSocialSignIn(
          credential: const SocialCredential(idToken: 'token'),
        ),
      );

      final pending = controller.signInWithSocial(SocialProvider.apple);
      expect(controller.pendingSocial, SocialProvider.apple);

      await pending;
      expect(controller.pendingSocial, isNull);
    });

    test('소셜 수단을 등록하지 않으면 버튼을 감추고 아무 일도 하지 않는다', () async {
      final repository = _StubAuthRepository();
      final controller = AuthController(repository);

      expect(controller.isSocialAvailable, isFalse);

      await controller.signInWithSocial(SocialProvider.google);

      expect(repository.socialIdToken, isNull);
      expect(controller.isSignedIn, isFalse);
    });

    test('Firebase가 준비되지 않으면 버튼을 감춘다', () {
      final controller = AuthController(
        _StubAuthRepository(),
        socialSignIn: FakeSocialSignIn(available: false),
      );

      expect(controller.isSocialAvailable, isFalse);
    });

    test('로그아웃하면 소셜 세션도 끊는다', () async {
      final social = FakeSocialSignIn(
        credential: const SocialCredential(idToken: 'token'),
      );
      final controller = AuthController(
        _StubAuthRepository(),
        socialSignIn: social,
      );
      await controller.signInWithSocial(SocialProvider.google);

      await controller.logout();

      // 끊지 않으면 다음 로그인에서 계정을 다시 고를 수 없습니다.
      expect(social.signOutCalled, isTrue);
      expect(controller.isSignedIn, isFalse);
    });
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
