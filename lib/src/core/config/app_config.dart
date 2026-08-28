/// 빌드 시점에 주입하는 앱 설정.
///
/// 예) flutter run --dart-define=TEUMSAE_API_BASE_URL=http://10.0.2.2:8080
///
/// 기본값은 웹(`teumsae-web/src/lib/config.ts`)과 같은 운영 서버를 가리킵니다.
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'TEUMSAE_API_BASE_URL',
    defaultValue: 'https://api.nolgo-shipper.com',
  );

  /// 서버가 세션 목록에 표시할 기기 라벨. 비우면 서버가 기본값을 씁니다.
  /// `RefreshTokenRequest.deviceLabel`은 100자 제한입니다.
  static const maxDeviceLabelLength = 100;

  static const connectTimeout = Duration(seconds: 8);
  static const receiveTimeout = Duration(seconds: 8);
}

/// 검색 기본값. 웹 `DEFAULT_SEARCH_PARAMS`와 동일하게 맞춥니다.
///
/// 선택 항목의 기본값(테마·예산·정렬 등)은 타입이 있는 열거형이라
/// `features/places/place_search_query.dart`에 있습니다.
abstract final class DefaultSearchParams {
  /// 서울 성북구 부근. 위치 권한을 아직 쓰지 않으므로 웹과 같은 기본 좌표를 씁니다.
  static const lat = 37.592;
  static const lng = 127.016;

  /// 서버 `PlaceSearchRequest`는 radius 100~5000, stayMinutes 0~360만 허용합니다.
  static const radius = 1500;
  static const stayMinutes = 0;

  /// 웹에도 날씨 선택 UI가 없어 항상 ANY로 보냅니다.
  static const weather = 'ANY';

  static const openOnly = false;
}
