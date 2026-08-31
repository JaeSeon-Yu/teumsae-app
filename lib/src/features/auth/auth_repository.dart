import 'dart:io';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/auth_tokens.dart';
import '../../core/storage/token_store.dart';
import 'auth_user.dart';

/// 인증 결과: 사용자 + 토큰.
class AuthSession {
  const AuthSession({required this.user, required this.tokens});

  final AuthUser user;
  final AuthTokens tokens;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      tokens: AuthTokens.fromJson(json),
    );
  }
}

/// 서버 `/api/auth/token/*` 호출과 토큰 보관을 담당합니다.
///
/// 앱은 쿠키를 쓸 수 없으므로 웹용 `/api/auth/*`가 아니라 토큰 엔드포인트를 씁니다.
class AuthRepository {
  AuthRepository({required ApiClient apiClient, required TokenStore tokenStore})
      : _apiClient = apiClient,
        _tokenStore = tokenStore;

  final ApiClient _apiClient;
  final TokenStore _tokenStore;

  static const _basePath = '/api/auth/token';

  Future<AuthSession> signup({
    required String username,
    required String password,
    String? nickname,
  }) async {
    final response = await _apiClient.postJson(
      '$_basePath/signup',
      body: {
        'username': username.trim(),
        'password': password,
        if (nickname != null && nickname.trim().isNotEmpty)
          'nickname': nickname.trim(),
        'deviceLabel': deviceLabel(),
      },
    );

    return _persist(AuthSession.fromJson(response));
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiClient.postJson(
      '$_basePath/login',
      body: {
        'username': username.trim(),
        'password': password,
        'deviceLabel': deviceLabel(),
      },
    );

    return _persist(AuthSession.fromJson(response));
  }

  /// Firebase idToken으로 로그인합니다. (구글·애플)
  ///
  /// 웹용 `/api/auth/firebase`와 같은 서비스를 쓰는 토큰 경로입니다.
  /// 처음이면 서버가 계정을 만들고, 있으면 그 계정으로 이어집니다.
  /// (`AuthService.firebaseLogin` → `provider=FIREBASE`, `providerId=Firebase uid`)
  Future<AuthSession> socialLogin({
    required String idToken,
    String? nickname,
  }) async {
    final response = await _apiClient.postJson(
      '$_basePath/firebase',
      body: {
        'idToken': idToken,
        if (nickname != null && nickname.trim().isNotEmpty)
          'nickname': nickname.trim(),
        'deviceLabel': deviceLabel(),
      },
    );

    return _persist(AuthSession.fromJson(response));
  }

  /// 저장된 refresh token으로 세션을 복구합니다. 없거나 만료면 `null`.
  Future<AuthSession?> restoreSession() async {
    final stored = await _tokenStore.read();
    if (stored == null) {
      return null;
    }

    try {
      final response = await _apiClient.postJson(
        '$_basePath/refresh',
        body: {
          'refreshToken': stored.refreshToken,
          'deviceLabel': deviceLabel(),
        },
      );
      return _persist(AuthSession.fromJson(response));
    } on Object {
      // 만료·폐기된 토큰이면 지우고 로그아웃 상태로 시작합니다.
      await _tokenStore.clear();
      return null;
    }
  }

  /// 이 기기의 세션만 폐기합니다. 서버 호출이 실패해도 로컬 토큰은 반드시 지웁니다.
  Future<void> logout() async {
    final stored = await _tokenStore.read();

    try {
      if (stored != null) {
        await _apiClient.postEmpty(
          '$_basePath/logout',
          body: {'refreshToken': stored.refreshToken},
        );
      }
    } on Object {
      // 네트워크가 끊겨도 이 기기에서는 로그아웃되어야 합니다.
    } finally {
      await _tokenStore.clear();
    }
  }

  // --- 아래 세 개는 토큰 전용 경로가 아니라 웹과 같은 `/api/auth/*`를 씁니다. ---
  // 서버 `JwtAuthenticationFilter`가 Authorization 헤더를 먼저 보기 때문에
  // 쿠키 없이도 그대로 동작합니다.

  /// 닉네임을 바꾸고 갱신된 사용자를 돌려줍니다.
  Future<AuthUser> updateNickname(String nickname) async {
    final response = await _apiClient.patchJson(
      '/api/auth/nickname',
      body: {'nickname': nickname.trim()},
    );

    return AuthUser.fromJson(response['user'] as Map<String, dynamic>);
  }

  /// 비밀번호를 바꾸고 **새 토큰으로 다시 로그인**합니다.
  ///
  /// 서버는 비밀번호가 바뀌면 그 사용자의 refresh token을 모두 폐기합니다.
  /// (`AuthService.changePassword` → `revokeAllForUser`)
  /// 그대로 두면 앱이 다음 갱신 시점에 로그아웃되므로, 바로 재로그인해 세션을 잇습니다.
  Future<AuthSession> changePassword({
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.postEmpty(
      '/api/auth/password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );

    return login(username: username, password: newPassword);
  }

  /// 계정을 비활성화(SUSPENDED)하고 로컬 토큰을 지웁니다.
  ///
  /// 서버가 refresh token을 모두 폐기하므로 남겨 둘 이유가 없습니다.
  Future<void> deleteAccount(String password) async {
    await _apiClient.deleteEmpty(
      '/api/auth/me',
      body: {'password': password},
    );
    await _tokenStore.clear();
  }

  Future<AuthSession> _persist(AuthSession session) async {
    await _tokenStore.write(session.tokens);
    return session;
  }

  /// 서버 세션 목록에 표시되는 기기 라벨. 100자 제한을 넘지 않게 자릅니다.
  static String deviceLabel() {
    final label = switch (Platform.operatingSystem) {
      'ios' => 'iOS ${Platform.operatingSystemVersion}',
      'android' => 'Android ${Platform.operatingSystemVersion}',
      final os => '$os ${Platform.operatingSystemVersion}',
    };

    return label.length > AppConfig.maxDeviceLabelLength
        ? label.substring(0, AppConfig.maxDeviceLabelLength)
        : label;
  }
}
