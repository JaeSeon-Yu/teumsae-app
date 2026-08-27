import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/core/network/auth_tokens.dart';
import 'package:teumsae_app/src/core/storage/token_store.dart';

void main() {
  group('InMemoryTokenStore', () {
    test('쓰고 읽고 지우는 흐름', () async {
      final store = InMemoryTokenStore();
      expect(await store.read(), isNull);

      final tokens = AuthTokens(
        tokenType: 'Bearer',
        accessToken: 'access',
        accessTokenExpiresAt: DateTime.utc(2026, 1, 1),
        refreshToken: 'refresh',
      );

      await store.write(tokens);
      expect((await store.read())?.refreshToken, 'refresh');

      await store.clear();
      expect(await store.read(), isNull);
    });
  });
}
