import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_bootstrap.dart';

/// 소셜 로그인이 끝나고 서버에 넘길 값.
///
/// [idToken]은 **Firebase** idToken입니다. 구글·애플이 준 토큰을 그대로 쓰지 않습니다.
/// 서버는 이것을 `POST /api/auth/token/firebase`로 받아
/// `provider=FIREBASE` + `providerId=Firebase uid`로 계정을 찾습니다.
/// 웹도 같은 방식이라 같은 구글 계정이면 웹과 앱이 한 계정으로 이어집니다.
class SocialCredential {
  const SocialCredential({required this.idToken, this.displayName});

  final String idToken;

  /// 소셜 계정에 등록된 이름. 새 계정을 만들 때 닉네임 후보로 씁니다.
  final String? displayName;
}

/// 소셜 로그인으로 고를 수 있는 수단. 화면의 버튼 상태 표시에 씁니다.
enum SocialProvider {
  google('Google', '구글'),
  apple('Apple', '애플'),
  ;

  const SocialProvider(this.label, this.koreanLabel);

  /// 버튼에 쓰는 원어 표기. (웹과 같게 `Google` · `Apple`)
  final String label;

  /// 문장 안에 넣는 한글 표기. ("구글 연동 중...")
  final String koreanLabel;
}

/// 소셜 로그인 실패. 화면에 그대로 쓸 한글 문구를 들고 있습니다.
class SocialSignInException implements Exception {
  const SocialSignInException(this.message);

  final String message;

  @override
  String toString() => 'SocialSignInException($message)';
}

/// 소셜 로그인. 테스트에서 가짜 구현으로 바꿀 수 있도록 인터페이스로 둡니다.
/// (Firebase·구글 SDK가 플랫폼 채널을 타므로 위젯 테스트에서 실제 구현을 쓸 수 없습니다)
abstract interface class SocialSignIn {
  /// 소셜 로그인을 쓸 수 있는 상태인지. `false`면 화면이 버튼을 감춥니다.
  bool get isAvailable;

  /// 못 쓰는 이유. [isAvailable]이 `true`면 `null`입니다.
  String? get unavailableReason;

  /// 사용자가 **취소하면 `null`** 을, 실패하면 [SocialSignInException]을 던집니다.
  ///
  /// 취소를 예외로 만들지 않은 이유: 앱에서 뒤로 가기·시트 닫기는 흔한 조작이라
  /// 그때마다 에러 배너가 뜨면 잘못한 것처럼 보입니다. (웹은 문구를 띄웁니다)
  Future<SocialCredential?> authenticate(SocialProvider provider);

  /// 앱에서 로그아웃할 때 Firebase 세션도 함께 끊습니다.
  ///
  /// 남겨 두면 다음 로그인에서 계정 선택 화면 없이 이전 계정으로 바로 들어가서,
  /// 다른 계정으로 바꿀 수 없습니다.
  Future<void> signOut();
}

/// Firebase Auth 기반 구현. 웹(`AuthForm.tsx`)과 같은 흐름입니다.
///
/// 구글은 `google_sign_in`으로 계정을 골라 Firebase 자격증명을 만들고,
/// 애플은 Firebase가 직접 처리합니다. (iOS는 네이티브 시트, Android는 웹 흐름)
class FirebaseSocialSignIn implements SocialSignIn {
  FirebaseSocialSignIn({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth,
        _googleSignIn = googleSignIn;

  final FirebaseAuth? _auth;
  final GoogleSignIn? _googleSignIn;

  bool _googleInitialized = false;

  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;
  GoogleSignIn get _google => _googleSignIn ?? GoogleSignIn.instance;

  @override
  bool get isAvailable => FirebaseBootstrap.isAvailable;

  @override
  String? get unavailableReason => FirebaseBootstrap.unavailableReason;

  @override
  Future<SocialCredential?> authenticate(SocialProvider provider) async {
    if (!isAvailable) {
      throw SocialSignInException(
        unavailableReason ?? '소셜 로그인을 준비하지 못했습니다.',
      );
    }

    final userCredential = switch (provider) {
      SocialProvider.google => await _signInWithGoogle(),
      SocialProvider.apple => await _signInWithApple(),
    };

    if (userCredential == null) {
      return null;
    }

    return _credentialOf(userCredential, provider);
  }

  @override
  Future<void> signOut() async {
    if (!isAvailable) {
      return;
    }

    try {
      // 구글은 계정 선택 상태가 Firebase와 별개라 둘 다 끊어야 합니다.
      await _google.signOut();
    } on Object {
      // 초기화 전이면 실패할 수 있습니다. Firebase 쪽만 끊어도 재로그인은 됩니다.
    }

    try {
      await _firebaseAuth.signOut();
    } on Object {
      // 로컬 세션을 지우는 작업이라 실패해도 앱 로그아웃을 막지 않습니다.
    }
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      if (!_googleInitialized) {
        // Android는 google-services.json의 웹 클라이언트를, iOS는 Info.plist의
        // GIDClientID를 읽습니다. 그래서 여기서 넘길 값이 없습니다.
        await _google.initialize();
        _googleInitialized = true;
      }

      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const SocialSignInException('구글 계정 정보를 받지 못했습니다.');
      }

      return await _firebaseAuth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw SocialSignInException(_googleMessage(error.code));
    } on FirebaseAuthException catch (error) {
      throw SocialSignInException(_firebaseMessage(error, SocialProvider.google));
    }
  }

  Future<UserCredential?> _signInWithApple() async {
    // 웹과 같은 범위를 요청합니다. 애플은 첫 로그인에서만 이름·이메일을 줍니다.
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');

    try {
      return await _firebaseAuth.signInWithProvider(provider);
    } on FirebaseAuthException catch (error) {
      if (_isCancellation(error.code)) {
        return null;
      }
      throw SocialSignInException(_firebaseMessage(error, SocialProvider.apple));
    }
  }

  Future<SocialCredential> _credentialOf(
    UserCredential userCredential,
    SocialProvider provider,
  ) async {
    final user = userCredential.user;
    final idToken = user == null ? null : await user.getIdToken();

    if (idToken == null || idToken.isEmpty) {
      throw SocialSignInException('${provider.koreanLabel} 로그인 정보를 받지 못했습니다.');
    }

    return SocialCredential(idToken: idToken, displayName: user?.displayName);
  }

  /// iOS·Android가 취소를 다른 코드로 알려 줘서 함께 봅니다.
  /// (`canceled`: 애플 시트 닫기, `web-context-canceled`: Android 웹 흐름 중단)
  static bool _isCancellation(String code) => const {
        'canceled',
        'cancelled',
        'user-cancelled',
        'web-context-canceled',
      }.contains(code);

  static String _googleMessage(GoogleSignInExceptionCode code) {
    return switch (code) {
      // SHA-1 미등록·클라이언트 ID 불일치가 여기로 옵니다. 사용자가 할 수 있는 게
      // 없으므로 다시 시도하라고 하지 않습니다.
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        '구글 로그인 설정이 올바르지 않습니다. 다른 방법으로 로그인해 주세요.',
      GoogleSignInExceptionCode.uiUnavailable =>
        '지금은 구글 로그인 창을 열 수 없습니다.',
      _ => '구글 로그인에 실패했습니다. 잠시 후 다시 시도해 주세요.',
    };
  }

  static String _firebaseMessage(
    FirebaseAuthException error,
    SocialProvider provider,
  ) {
    final name = provider.koreanLabel;

    return switch (error.code) {
      // Firebase 콘솔에서 해당 로그인 수단을 켜지 않은 경우.
      'operation-not-allowed' ||
      'configuration-not-found' =>
        '$name 로그인이 아직 준비되지 않았습니다. 다른 방법으로 로그인해 주세요.',
      // 같은 이메일이 다른 수단으로 이미 가입된 경우.
      'account-exists-with-different-credential' =>
        '이미 다른 방법으로 가입한 이메일입니다. 기존 방법으로 로그인해 주세요.',
      'invalid-credential' => '$name 로그인 정보가 올바르지 않습니다. 다시 시도해 주세요.',
      'user-disabled' => '이 계정은 사용할 수 없습니다.',
      'network-request-failed' => '네트워크 연결을 확인해 주세요.',
      _ => '$name 로그인에 실패했습니다. 잠시 후 다시 시도해 주세요.',
    };
  }
}

/// 테스트·프리뷰용 구현. 앱 실행 코드에서는 쓰지 않습니다.
class FakeSocialSignIn implements SocialSignIn {
  FakeSocialSignIn({
    this.credential,
    this.error,
    this.available = true,
  });

  /// 지정하면 [authenticate]가 이 값을 돌려줍니다. `null`이면 사용자가 취소한 것으로 봅니다.
  final SocialCredential? credential;

  /// 지정하면 [authenticate]가 이 예외를 던집니다.
  final Object? error;

  final bool available;

  /// [authenticate]에 넘어온 수단. 어떤 버튼이 눌렸는지 확인할 때 씁니다.
  SocialProvider? requestedProvider;
  bool signOutCalled = false;

  @override
  bool get isAvailable => available;

  @override
  String? get unavailableReason => available ? null : '소셜 로그인을 준비하지 못했습니다.';

  @override
  Future<SocialCredential?> authenticate(SocialProvider provider) async {
    requestedProvider = provider;
    if (error != null) {
      throw error!;
    }
    return credential;
  }

  @override
  Future<void> signOut() async => signOutCalled = true;
}
