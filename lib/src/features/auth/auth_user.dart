/// 서버 `AuthUserResponse`.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.nickname,
    required this.role,
    required this.provider,
  });

  final int id;
  final String username;
  final String nickname;

  /// 서버 `UserRole` (USER / ADMIN).
  final String role;

  /// 서버 `SocialProvider` (LOCAL / GOOGLE / APPLE / FIREBASE).
  final String provider;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      // 서버는 nickname이 비면 username을 채워 보냅니다(`displayNickname`).
      nickname: json['nickname'] as String? ?? json['username'] as String,
      role: json['role'] as String? ?? 'USER',
      provider: json['provider'] as String? ?? 'LOCAL',
    );
  }

  bool get isAdmin => role == 'ADMIN';
}
