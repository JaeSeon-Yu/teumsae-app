import '../../core/network/api_client.dart';
import 'place_detail.dart';
import 'place_review.dart';
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

  /// 후기 작성. 로그인이 필요합니다. 서버는 201과 작성된 후기를 돌려줍니다.
  Future<PlaceReview> createReview({
    required int placeId,
    required int rating,
    required String comment,
  }) async {
    return PlaceReview.fromJson(
      await _apiClient.postJson(
        '/api/places/$placeId/reviews',
        body: {'rating': rating, 'comment': comment},
      ),
    );
  }

  /// 후기 삭제(204). 본인 후기이거나 관리자만 됩니다. 아니면 서버가 403을 줍니다.
  Future<void> deleteReview({
    required int placeId,
    required int reviewId,
  }) {
    return _apiClient.deleteEmpty('/api/places/$placeId/reviews/$reviewId');
  }
}
