/// 서버 `TokenAuthResponse`의 토큰 부분.
///
/// 서버는 만료를 "남은 초"로 주기 때문에, 받은 시점을 기준으로 절대 시각으로 바꿔
/// 보관합니다. 앱이 백그라운드에 오래 있어도 만료 판단이 어긋나지 않습니다.
class AuthTokens {
  const AuthTokens({
    required this.tokenType,
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
  });

  final String tokenType;
  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;

  /// 서버 응답(JSON)에서 생성합니다. [now]는 테스트에서 시각을 고정하기 위한 인자입니다.
  factory AuthTokens.fromJson(Map<String, dynamic> json, {DateTime? now}) {
    final issuedAt = now ?? DateTime.now();
    final expiresInSeconds = (json['accessTokenExpiresInSeconds'] as num).toInt();

    return AuthTokens(
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      accessToken: json['accessToken'] as String,
      accessTokenExpiresAt: issuedAt.add(Duration(seconds: expiresInSeconds)),
      refreshToken: json['refreshToken'] as String,
    );
  }

  String get authorizationHeader => '$tokenType $accessToken';

  /// 만료 [leeway] 전부터 만료된 것으로 취급해 요청 도중 만료되는 상황을 줄입니다.
  bool isExpired({DateTime? now, Duration leeway = const Duration(seconds: 30)}) {
    final reference = (now ?? DateTime.now()).add(leeway);
    return !reference.isBefore(accessTokenExpiresAt);
  }
}
