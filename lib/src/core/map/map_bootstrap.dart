import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../config/app_config.dart';

/// 네이버 지도 SDK 준비 상태.
///
/// SDK 초기화는 앱 전체에 한 번뿐이고 `runApp` 전에 끝나야 해서
/// GetX 의존성 대신 정적 상태로 둡니다. 화면은 이 값을 직접 읽지 않고
/// `PlaceMapBuilder`를 통해 봅니다. (테스트에서 대역으로 바꿀 수 있도록)
abstract final class MapBootstrap {
  static String? _unavailableReason;

  /// 지도를 그릴 수 있는 상태인지.
  static bool get isAvailable => _unavailableReason == null;

  /// 지도를 못 쓰는 이유. 화면에 그대로 보여 줄 한글 문구입니다.
  static String? get unavailableReason => _unavailableReason;

  /// `runApp` 전에 한 번 호출합니다.
  ///
  /// 키가 없거나 인증이 거부되면 예외를 던지지 않고 이유만 남깁니다.
  /// 지도는 앱의 일부일 뿐이라 검색·저장 같은 나머지 기능은 계속 써야 합니다.
  static Future<void> initialize() async {
    if (AppConfig.naverMapClientId.isEmpty) {
      _unavailableReason = '네이버 지도 Client ID가 설정되지 않았습니다.';
      return;
    }

    try {
      await FlutterNaverMap().init(
        clientId: AppConfig.naverMapClientId,
        // 인증 실패는 초기화 이후 비동기로 통보됩니다.
        // (키가 틀렸거나 앱 식별자가 NCP에 등록되지 않은 경우)
        onAuthFailed: (exception) {
          _unavailableReason = '네이버 지도 인증에 실패했습니다. (${exception.code})';
        },
      );
      _unavailableReason = null;
    } on Object {
      _unavailableReason = '네이버 지도를 준비하지 못했습니다.';
    }
  }
}
