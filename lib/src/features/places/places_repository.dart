import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import 'place_summary.dart';

/// 검색 조건. 서버 `PlaceSearchRequest`의 허용 범위를 그대로 따릅니다.
class PlaceSearchQuery {
  const PlaceSearchQuery({
    this.lat = DefaultSearchParams.lat,
    this.lng = DefaultSearchParams.lng,
    this.radius = DefaultSearchParams.radius,
    this.stayMinutes = DefaultSearchParams.stayMinutes,
    this.theme = DefaultSearchParams.theme,
    this.sort = DefaultSearchParams.sort,
    this.openOnly = DefaultSearchParams.openOnly,
  });

  final double lat;
  final double lng;

  /// 100~5000 (서버가 범위를 벗어나면 400을 반환합니다)
  final int radius;

  /// 0~360
  final int stayMinutes;
  final String theme;
  final String sort;
  final bool openOnly;

  PlaceSearchQuery copyWith({
    int? radius,
    String? theme,
    String? sort,
    bool? openOnly,
  }) {
    return PlaceSearchQuery(
      lat: lat,
      lng: lng,
      radius: radius ?? this.radius,
      stayMinutes: stayMinutes,
      theme: theme ?? this.theme,
      sort: sort ?? this.sort,
      openOnly: openOnly ?? this.openOnly,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return {
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'stayMinutes': stayMinutes,
      'budget': DefaultSearchParams.budget,
      'weather': DefaultSearchParams.weather,
      'space': DefaultSearchParams.space,
      'sort': sort,
      'theme': theme,
      'openOnly': openOnly,
    };
  }
}

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
}
