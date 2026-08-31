import 'package:firebase_core/firebase_core.dart';

/// Firebase 준비 상태.
///
/// 초기화는 앱 전체에 한 번뿐이고 `runApp` 전에 끝나야 해서 GetX 의존성 대신
/// 정적 상태로 둡니다. [MapBootstrap]과 같은 구성입니다. 화면은 이 값을 직접 읽지
/// 않고 `SocialSignIn`을 통해 봅니다. (테스트에서 대역으로 바꿀 수 있도록)
///
/// 설정은 네이티브 파일에서 읽습니다.
/// (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`)
/// 그래서 `firebase_options.dart`를 만들지 않고, 앱은 Android·iOS만 지원합니다.
abstract final class FirebaseBootstrap {
  /// [initialize]가 성공하기 전에는 준비되지 않은 상태입니다.
  /// (초기화를 잊었을 때 소셜 버튼이 보였다가 눌러야 실패하는 상황을 막습니다)
  static String? _unavailableReason = '소셜 로그인을 준비하지 못했습니다.';

  /// 소셜 로그인을 쓸 수 있는 상태인지.
  static bool get isAvailable => _unavailableReason == null;

  /// 소셜 로그인을 못 쓰는 이유. 화면에 그대로 보여 줄 한글 문구입니다.
  static String? get unavailableReason => _unavailableReason;

  /// `runApp` 전에 한 번 호출합니다.
  ///
  /// 설정 파일이 없거나 잘못돼도 예외를 던지지 않고 이유만 남깁니다.
  /// 소셜 로그인은 로그인 수단 하나일 뿐이라, 실패해도 아이디·비밀번호 로그인과
  /// 검색·저장은 그대로 써야 합니다. 로그인 화면에서는 소셜 버튼만 감춥니다.
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _unavailableReason = null;
    } on Object {
      // 설정 파일 누락, 번들 ID/패키지 이름 불일치가 여기로 옵니다.
      _unavailableReason = '소셜 로그인을 준비하지 못했습니다.';
    }
  }
}
