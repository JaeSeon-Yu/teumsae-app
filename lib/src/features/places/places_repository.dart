import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'place_detail.dart';
import 'place_form.dart';
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

  /// 내가 등록한 장소. 서버가 수정 시각 최신순으로 정렬해 줍니다.
  Future<List<PlaceDetail>> myPlaces() async {
    final response = await _apiClient.getJson('/api/places/me');
    final items = response['items'];
    if (items is! List) {
      return const [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(PlaceDetail.fromJson)
        .toList(growable: false);
  }

  /// 장소 등록. 서버가 만들어진 장소를 그대로 돌려줍니다.
  Future<PlaceDetail> createPlace(Map<String, dynamic> body) async {
    return PlaceDetail.fromJson(
      await _apiClient.postJson('/api/places', body: body),
    );
  }

  /// 장소 수정. 직접 등록한 장소만 됩니다. 아니면 서버가 403을 줍니다.
  Future<PlaceDetail> updatePlace(
    int id,
    Map<String, dynamic> body,
  ) async {
    return PlaceDetail.fromJson(
      await _apiClient.putJson('/api/places/$id', body: body),
    );
  }

  /// 장소 삭제(204). 수정과 같은 조건입니다.
  Future<void> deletePlace(int id) {
    return _apiClient.deleteEmpty('/api/places/$id');
  }

  /// 고를 수 있는 태그. 서버가 아는 라벨만 보낼 수 있어서 목록을 받아 씁니다.
  Future<List<PlaceTagOption>> tags() async {
    final response = await _apiClient.getJsonList('/api/places/tags');
    return response
        .whereType<Map<String, dynamic>>()
        .map(PlaceTagOption.fromJson)
        .toList(growable: false);
  }

  /// 좌표로 주소를 찾습니다. 못 찾으면 서버가 404를 주므로 `null`로 바꿉니다.
  ///
  /// 주소를 비워 보내도 서버가 같은 조회를 하지만, 핀을 옮길 때 화면에서
  /// 바로 보여 주려면 앱도 물어봐야 합니다.
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _apiClient.getJson(
        '/api/places/geocode/reverse',
        query: {'lat': lat, 'lng': lng},
      );
      final address = response['address'];
      return address is String && address.trim().isNotEmpty ? address : null;
    } on ApiException {
      return null;
    }
  }
}
