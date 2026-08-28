import 'place_format.dart';

/// 서버 `PlaceSummary` 중 목록 표시에 필요한 필드만 담습니다.
///
/// 서버가 필드를 더 내려주더라도 무시합니다. 화면에서 쓰는 값만 파싱해 두면
/// 서버 응답이 늘어나도 앱을 고칠 필요가 없습니다.
class PlaceSummary {
  const PlaceSummary({
    required this.id,
    required this.name,
    required this.typeLabel,
    required this.address,
    required this.lat,
    required this.lng,
    required this.distanceMeters,
    required this.priceLabel,
    required this.restScore,
    required this.scoreLabel,
    required this.reasons,
    required this.tags,
    this.openStatusLabel,
  });

  final int id;
  final String name;
  final String typeLabel;
  final String address;

  /// 지도 마커 위치. 목록 화면에서는 쓰지 않습니다.
  final double lat;
  final double lng;

  final int distanceMeters;
  final String priceLabel;
  final int restScore;
  final String scoreLabel;
  final List<String> reasons;
  final List<String> tags;
  final String? openStatusLabel;

  factory PlaceSummary.fromJson(Map<String, dynamic> json) {
    return PlaceSummary(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      typeLabel: json['typeLabel'] as String? ?? '',
      address: json['address'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      distanceMeters: (json['distanceMeters'] as num?)?.round() ?? 0,
      priceLabel: json['priceLabel'] as String? ?? '',
      restScore: (json['restScore'] as num?)?.round() ?? 0,
      scoreLabel: json['scoreLabel'] as String? ?? '',
      reasons: _stringList(json['reasons']),
      tags: _stringList(json['tags']),
      openStatusLabel: json['openStatusLabel'] as String?,
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return const [];
  }

  /// 1km 미만은 m, 그 이상은 km로 표시합니다. (웹 `formatDistance`와 같은 규칙)
  String get distanceLabel => PlaceFormat.distance(distanceMeters);
}
