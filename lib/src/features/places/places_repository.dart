import '../../core/network/api_client.dart';
import 'place_detail.dart';
import 'place_search_query.dart';
import 'place_summary.dart';

class PlacesRepository {
  PlacesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<PlaceSummary>> search(PlaceSearchQuery query) async {
    final response = await _apiClient.getJson(
      '/api/places/search',
      query: query.toQueryParameters(),
    );

    final items = response['items'];
    if (items is! List) {
      return const [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(PlaceSummary.fromJson)
        .toList(growable: false);
  }

  /// 로그인하지 않아도 조회됩니다. 이때 `saved`는 항상 `false`입니다.
  Future<PlaceDetail> getPlace(int id) async {
    return PlaceDetail.fromJson(await _apiClient.getJson('/api/places/$id'));
  }
}
