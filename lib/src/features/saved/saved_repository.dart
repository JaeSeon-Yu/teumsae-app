import '../../core/network/api_client.dart';
import 'saved_place.dart';

/// 저장 목록. 세 엔드포인트 모두 로그인이 필요합니다.
///
/// 저장·저장 취소는 서버에서 멱등하게 동작합니다.
/// (이미 저장된 장소를 다시 저장하거나 없는 저장을 지워도 204를 줍니다)
class SavedRepository {
  SavedRepository(this._apiClient);

  final ApiClient _apiClient;

  static const _basePath = '/api/saved-places';

  Future<List<SavedPlace>> list() async {
    final response = await _apiClient.getJson(_basePath);

    final items = response['items'];
    if (items is! List) {
      return const [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(SavedPlace.fromJson)
        .toList(growable: false);
  }

  Future<void> save(int placeId) => _apiClient.postEmpty('$_basePath/$placeId');

  Future<void> unsave(int placeId) =>
      _apiClient.deleteEmpty('$_basePath/$placeId');
}
