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
