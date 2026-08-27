import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/core/network/auth_tokens.dart';

void main() {
  group('AuthTokens.fromJson', () {
    test('남은 초를 발급 시점 기준 절대 시각으로 바꾼다', () {
      final issuedAt = DateTime.utc(2026, 1, 1, 12);

      final tokens = AuthTokens.fromJson(
        const {
          'tokenType': 'Bearer',
          'accessToken': 'access-token-value',
          'accessTokenExpiresInSeconds': 3600,
          'refreshToken': 'refresh-token-value',
          'refreshTokenExpiresInSeconds': 5184000,
        },
        now: issuedAt,
      );

      expect(tokens.accessTokenExpiresAt, issuedAt.add(const Duration(hours: 1)));
      expect(tokens.authorizationHeader, 'Bearer access-token-value');
      expect(tokens.refreshToken, 'refresh-token-value');
    });

    test('tokenType이 없으면 Bearer로 본다', () {
      final tokens = AuthTokens.fromJson(
        const {
          'accessToken': 'a',
          'accessTokenExpiresInSeconds': 60,
          'refreshToken': 'r',
        },
        now: DateTime.utc(2026, 1, 1),
      );

      expect(tokens.tokenType, 'Bearer');
    });
  });

  group('isExpired', () {
    final expiresAt = DateTime.utc(2026, 1, 1, 12);
    final tokens = AuthTokens(
      tokenType: 'Bearer',
      accessToken: 'a',
      accessTokenExpiresAt: expiresAt,
      refreshToken: 'r',
    );

    test('만료 전이면 false', () {
      expect(
        tokens.isExpired(now: expiresAt.subtract(const Duration(minutes: 5))),
        isFalse,
      );
    });

    test('여유 시간(기본 30초) 안에 들어오면 미리 만료로 본다', () {
      // 요청이 날아가는 도중 만료되는 상황을 막기 위한 동작입니다.
      expect(
        tokens.isExpired(now: expiresAt.subtract(const Duration(seconds: 10))),
        isTrue,
      );
    });

    test('만료 시각을 지나면 true', () {
      expect(
        tokens.isExpired(now: expiresAt.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('여유 시간을 0으로 주면 만료 직전까지 유효', () {
      expect(
        tokens.isExpired(
          now: expiresAt.subtract(const Duration(seconds: 1)),
          leeway: Duration.zero,
        ),
        isFalse,
      );
    });
  });
}
