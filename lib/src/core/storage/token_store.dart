import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/auth_tokens.dart';

/// 토큰 보관소. 테스트에서 가짜 구현으로 바꿀 수 있도록 인터페이스로 둡니다.
abstract interface class TokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

/// refresh token은 장기 자격증명이라 반드시 OS 보안 저장소에 둡니다.
/// (iOS Keychain / Android KeyStore + AES-GCM)
/// SharedPreferences처럼 평문으로 저장하면 루팅·탈옥 기기에서 그대로 노출됩니다.
class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              // v11 기본값이 AES-GCM + KeyStore 키 래핑입니다. 별도 설정이 필요 없습니다.
              aOptions: AndroidOptions(storageNamespace: 'teumsae'),
              iOptions: IOSOptions(
                // 기기 재시작 후 한 번 잠금 해제되면 접근 가능. 백그라운드 갱신에 필요합니다.
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _tokenTypeKey = 'teumsae.token_type';
  static const _accessTokenKey = 'teumsae.access_token';
  static const _accessTokenExpiresAtKey = 'teumsae.access_token_expires_at';
  static const _refreshTokenKey = 'teumsae.refresh_token';

  @override
  Future<AuthTokens?> read() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final expiresAtRaw = await _storage.read(key: _accessTokenExpiresAtKey);

    if (accessToken == null || refreshToken == null || expiresAtRaw == null) {
      return null;
    }

    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (expiresAt == null) {
      // 저장 값이 깨졌으면 지우고 로그아웃 상태로 되돌립니다.
      await clear();
      return null;
    }

    return AuthTokens(
      tokenType: await _storage.read(key: _tokenTypeKey) ?? 'Bearer',
      accessToken: accessToken,
      accessTokenExpiresAt: expiresAt,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    await Future.wait([
      _storage.write(key: _tokenTypeKey, value: tokens.tokenType),
      _storage.write(key: _accessTokenKey, value: tokens.accessToken),
      _storage.write(
        key: _accessTokenExpiresAtKey,
        value: tokens.accessTokenExpiresAt.toIso8601String(),
      ),
      _storage.write(key: _refreshTokenKey, value: tokens.refreshToken),
    ]);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _tokenTypeKey),
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _accessTokenExpiresAtKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}

/// 테스트·프리뷰용 메모리 보관소. 앱 실행 코드에서는 쓰지 않습니다.
class InMemoryTokenStore implements TokenStore {
  InMemoryTokenStore([this._tokens]);

  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
