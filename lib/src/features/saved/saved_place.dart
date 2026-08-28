import '../places/place_format.dart';

/// 서버 `SavedPlaceResponse`.
///
/// 저장 목록은 검색이 아니라서 거리·점수·추천 이유가 없습니다.
/// 그래서 [PlaceSummary]를 재사용하지 않고 별도 모델을 둡니다.
class SavedPlace {
  const SavedPlace({
    required this.id,
    required this.name,
    required this.typeLabel,
    required this.address,
    required this.priceLabel,
    required this.indoor,
    required this.outdoor,
    required this.stayMinutesMin,
    required this.stayMinutesMax,
    required this.tags,
    this.estimatedCostMin,
    this.estimatedCostMax,
    this.savedAt,
  });

  final int id;
  final String name;
  final String typeLabel;
  final String address;
  final String priceLabel;
  final bool indoor;
  final bool outdoor;
  final int stayMinutesMin;
  final int stayMinutesMax;
  final List<String> tags;
  final int? estimatedCostMin;
  final int? estimatedCostMax;

  /// 저장한 시각. 서버가 `LocalDateTime`(시간대 없음)으로 주므로 그대로 읽습니다.
  final DateTime? savedAt;

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      typeLabel: json['typeLabel'] as String? ?? '',
      address: json['address'] as String? ?? '',
      priceLabel: json['priceLabel'] as String? ?? '',
      indoor: json['indoor'] as bool? ?? false,
      outdoor: json['outdoor'] as bool? ?? false,
      stayMinutesMin: (json['stayMinutesMin'] as num?)?.round() ?? 0,
      stayMinutesMax: (json['stayMinutesMax'] as num?)?.round() ?? 0,
      tags: json['tags'] is List
          ? (json['tags'] as List).whereType<String>().toList(growable: false)
          : const [],
      estimatedCostMin: (json['estimatedCostMin'] as num?)?.toInt(),
      estimatedCostMax: (json['estimatedCostMax'] as num?)?.toInt(),
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? ''),
    );
  }

  String get costLabel =>
      PlaceFormat.cost(estimatedCostMin, estimatedCostMax, priceLabel);

  String get spaceLabel => PlaceFormat.space(indoor: indoor, outdoor: outdoor);

  String get stayLabel =>
      PlaceFormat.stayRange(stayMinutesMin, stayMinutesMax);

  /// "2026. 8. 28. 저장" 형태. intl 없이 웹의 `toLocaleDateString("ko-KR")`에 맞춥니다.
  String? get savedAtLabel {
    final savedAt = this.savedAt;
    if (savedAt == null) return null;
    return '${savedAt.year}. ${savedAt.month}. ${savedAt.day}. 저장';
  }
}
