import '../../core/network/api_client.dart';
import 'user_profile.dart';

class UsersRepository {
  UsersRepository(this._apiClient);

  final ApiClient _apiClient;

  /// 공개 프로필. 로그인 없이도 조회됩니다.
  Future<UserProfile> getProfile(String username) async {
    return UserProfile.fromJson(
      await _apiClient.getJson('/api/users/${Uri.encodeComponent(username)}'),
    );
  }

  /// 차단한 사용자 id 목록. 서버가 숫자 배열만 줍니다.
  Future<Set<int>> blockedUserIds() async {
    final response = await _apiClient.getJsonList('/api/users/blocks');
    return response
        .whereType<num>()
        .map((id) => id.toInt())
        .toSet();
  }

  /// 차단. 서버는 200에 본문 없이 응답합니다. (204가 아닙니다)
  Future<void> block(int userId) {
    return _apiClient.postEmpty('/api/users/blocks/$userId');
  }

  Future<void> unblock(int userId) {
    return _apiClient.deleteEmpty('/api/users/blocks/$userId');
  }

  /// 신고. 관리자가 웹에서 확인합니다.
  Future<void> report({
    required ReportTarget target,
    required int targetId,
    required String reason,
    String? details,
  }) {
    return _apiClient.postEmpty(
      '/api/reports',
      body: {
        'targetType': target.value,
        'targetId': targetId,
        'reason': reason.trim(),
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      },
    );
  }
}
