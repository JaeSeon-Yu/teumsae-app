import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:teumsae_app/src/core/config/app_config.dart';
import 'package:teumsae_app/src/core/map/map_bootstrap.dart';
import 'package:teumsae_app/src/core/theme/app_theme.dart';
import 'package:teumsae_app/src/features/places/place_map.dart';

/// 네이버 지도 Client ID가 실제로 통하는지 확인합니다.
///
/// 위젯 테스트로는 확인할 수 없습니다. 지도는 플랫폼 뷰라 실기기·시뮬레이터에서만
/// 그려지고, 인증도 그때 네이버 서버와 이뤄집니다.
///
/// ```bash
/// flutter test integration_test/map_auth_test.dart \
///   -d <device-id> --dart-define-from-file=dart_define.json
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('지도 SDK가 Client ID로 인증된다', (tester) async {
    expect(
      AppConfig.naverMapClientId,
      isNotEmpty,
      reason: '--dart-define-from-file=dart_define.json으로 Client ID를 넣어야 합니다.',
    );

    await MapBootstrap.initialize();
    expect(
      MapBootstrap.isAvailable,
      isTrue,
      reason: '초기화 실패: ${MapBootstrap.unavailableReason}',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: const NaverPlaceMapBuilder().single(
            lat: 37.592,
            lng: 127.016,
            name: '성북구립도서관',
          ),
        ),
      ),
    );

    // 인증 실패는 지도를 만든 뒤 비동기로 통보됩니다. 넉넉히 기다립니다.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(seconds: 1));
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!MapBootstrap.isAvailable) {
        break;
      }
    }

    expect(
      MapBootstrap.isAvailable,
      isTrue,
      reason: '지도 인증 실패: ${MapBootstrap.unavailableReason}',
    );
  });
}
