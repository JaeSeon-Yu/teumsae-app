import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/core/network/api_client.dart';
import 'package:teumsae_app/src/core/network/api_exception.dart';
import 'package:teumsae_app/src/core/network/auth_tokens.dart';
import 'package:teumsae_app/src/core/storage/token_store.dart';
import 'package:teumsae_app/src/features/account/settings_controller.dart';
import 'package:teumsae_app/src/features/auth/auth_controller.dart';
import 'package:teumsae_app/src/features/auth/auth_repository.dart';
import 'package:teumsae_app/src/features/auth/auth_user.dart';

AuthUser _user({String nickname = '틈새유저'}) => AuthUser(
      id: 1,
      username: 'teumsae_user',
      nickname: nickname,
      role: 'USER',
      provider: 'LOCAL',
    );

AuthSession _session({String nickname = '틈새유저'}) => AuthSession(
      user: _user(nickname: nickname),
      tokens: AuthTokens(
        tokenType: 'Bearer',
        accessToken: 'access',
        accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
        refreshToken: 'refresh',
      ),
    );

class _StubAuthRepository extends AuthRepository {
  _StubAuthRepository({this.error})
      : super(
          apiClient: ApiClient(tokenStore: InMemoryTokenStore()),
          tokenStore: InMemoryTokenStore(),
        );

  final Object? error;

  String? updatedNickname;
  ({String username, String current, String next})? changedPassword;
  String? deletedWithPassword;

  @override
  Future<AuthSession?> restoreSession() async => _session();

  @override
  Future<AuthUser> updateNickname(String nickname) async {
    if (error != null) throw error!;
    updatedNickname = nickname;
    return _user(nickname: nickname);
  }

  @override
  Future<AuthSession> changePassword({
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (error != null) throw error!;
    changedPassword = (
      username: username,
      current: currentPassword,
      next: newPassword,
    );
    return _session();
  }

  @override
  Future<void> deleteAccount(String password) async {
    if (error != null) throw error!;
    deletedWithPassword = password;
  }
}

/// 로그인된 상태의 컨트롤러 쌍을 만듭니다.
Future<(SettingsController, AuthController)> _signedIn(
  _StubAuthRepository repository,
) async {
  final auth = AuthController(repository);
  await auth.restoreSession();
  return (SettingsController(auth), auth);
}

void main() {
  group('닉네임', () {
    test('성공하면 로그인 사용자 정보까지 갱신된다', () async {
      final repository = _StubAuthRepository();
      final (settings, auth) = await _signedIn(repository);

      await settings.submitNickname('새 닉네임');

      expect(repository.updatedNickname, '새 닉네임');
      expect(auth.user?.nickname, '새 닉네임');
      expect(settings.nickname.successMessage, '닉네임을 저장했습니다.');
      expect(settings.nickname.isSubmitting, isFalse);
    });

    test('실패하면 서버 메시지를 그대로 노출한다', () async {
      final (settings, auth) = await _signedIn(
        _StubAuthRepository(
          error: const ApiException(statusCode: 400, message: '닉네임이 너무 짧습니다.'),
        ),
      );

      await settings.submitNickname('짧');

      expect(settings.nickname.errorMessage, '닉네임이 너무 짧습니다.');
      expect(auth.user?.nickname, '틈새유저');
    });
  });

  group('비밀번호', () {
    test('확인이 어긋나면 서버를 부르지 않는다', () async {
      final repository = _StubAuthRepository();
      final (settings, _) = await _signedIn(repository);

      await settings.submitPassword(
        currentPassword: 'old-password',
        newPassword: 'new-password',
        confirmPassword: 'new-password-typo',
      );

      expect(settings.password.errorMessage, '새 비밀번호가 서로 일치하지 않습니다.');
      expect(repository.changedPassword, isNull);
    });

    test('성공하면 새 비밀번호로 재로그인해 세션을 잇는다', () async {
      // 서버가 비밀번호 변경 시 기존 refresh token을 모두 폐기하기 때문입니다.
      final repository = _StubAuthRepository();
      final (settings, auth) = await _signedIn(repository);

      await settings.submitPassword(
        currentPassword: 'old-password',
        newPassword: 'new-password',
        confirmPassword: 'new-password',
      );

      expect(repository.changedPassword?.username, 'teumsae_user');
      expect(repository.changedPassword?.next, 'new-password');
      expect(settings.password.successMessage, '비밀번호를 변경했습니다.');
      expect(auth.isSignedIn, isTrue);
    });

    test('현재 비밀번호가 틀리면 서버 메시지를 노출한다', () async {
      final (settings, _) = await _signedIn(
        _StubAuthRepository(
          error: const ApiException(
            statusCode: 400,
            message: '현재 비밀번호가 올바르지 않습니다.',
          ),
        ),
      );

      await settings.submitPassword(
        currentPassword: 'wrong',
        newPassword: 'new-password',
        confirmPassword: 'new-password',
      );

      expect(settings.password.errorMessage, '현재 비밀번호가 올바르지 않습니다.');
    });
  });

  group('회원 탈퇴', () {
    test('성공하면 로그아웃 상태가 된다', () async {
      final repository = _StubAuthRepository();
      final (settings, auth) = await _signedIn(repository);

      final result = await settings.submitDeleteAccount('password');

      expect(result, isTrue);
      expect(repository.deletedWithPassword, 'password');
      expect(auth.isSignedIn, isFalse);
    });

    test('실패하면 로그인 상태를 유지한다', () async {
      final (settings, auth) = await _signedIn(
        _StubAuthRepository(
          error: const ApiException(
            statusCode: 400,
            message: '현재 비밀번호가 올바르지 않습니다.',
          ),
        ),
      );

      final result = await settings.submitDeleteAccount('wrong');

      expect(result, isFalse);
      expect(settings.deleteAccount.errorMessage, '현재 비밀번호가 올바르지 않습니다.');
      expect(auth.isSignedIn, isTrue);
    });
  });
}
