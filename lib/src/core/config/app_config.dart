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

  /// 네이버 지도 Client ID. 웹의 `NEXT_PUBLIC_NAVER_MAP_CLIENT_ID`에 대응합니다.
  ///
  /// NCP 콘솔 > Services > Application Services > Maps에서 Application을 만들고
  /// **Mobile Dynamic Map**을 켠 뒤, Android 패키지 이름과 iOS Bundle ID로
  /// `kr.co.jason.teumsae`를 등록해야 발급된 키가 앱에서 통합니다.
  /// (웹 키를 그대로 쓰면 인증이 거부됩니다. 등록된 앱 식별자가 없기 때문입니다)
  ///
  /// 비워 두면 지도 자리에 안내 문구가 뜨고 나머지 기능은 그대로 동작합니다.
  static const naverMapClientId = String.fromEnvironment(
    'TEUMSAE_NAVER_MAP_CLIENT_ID',
  );

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
