import 'place_format.dart';
import 'place_review.dart';

/// 서버 `PlaceFacilityScores`. 각 항목 0~5점.
class PlaceFacilityScores {
  const PlaceFacilityScores({
    required this.seating,
    required this.wifi,
    required this.toilet,
    required this.charging,
    required this.quiet,
    required this.laptop,
  });

  final int seating;
  final int wifi;
  final int toilet;
  final int charging;
  final int quiet;
  final int laptop;

  factory PlaceFacilityScores.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    return PlaceFacilityScores(
      seating: _score(map['seating']),
      wifi: _score(map['wifi']),
      toilet: _score(map['toilet']),
      charging: _score(map['charging']),
      quiet: _score(map['quiet']),
      laptop: _score(map['laptop']),
    );
  }

  /// 화면 표시 순서. 웹 `FeatureScores`와 같은 순서를 유지합니다.
  List<(String, int)> get labelled => [
        ('좌석', seating),
        ('와이파이', wifi),
        ('화장실', toilet),
        ('충전', charging),
        ('조용함', quiet),
        ('노트북', laptop),
      ];
}

/// 서버 `PlaceWeatherScores`. 각 항목 0~5점.
class PlaceWeatherScores {
  const PlaceWeatherScores({
    required this.rain,
    required this.heat,
    required this.cold,
    required this.sunny,
  });

  final int rain;
  final int heat;
  final int cold;
  final int sunny;

  factory PlaceWeatherScores.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    return PlaceWeatherScores(
      rain: _score(map['rain']),
      heat: _score(map['heat']),
      cold: _score(map['cold']),
      sunny: _score(map['sunny']),
    );
  }

  List<(String, int)> get labelled => [
        ('비 대기', rain),
        ('더위 쉼', heat),
        ('추위 쉼', cold),
        ('야외 휴식', sunny),
      ];
}

/// 서버 `PlaceDetailResponse`.
///
/// 검색 결과(`PlaceSummary`)와 달리 `restScore`·`distanceMeters`·`reasons`가 없습니다.
/// 상세 조회는 검색 조건 없이 장소 하나만 보는 것이어서 서버가 점수를 계산하지 않습니다.
/// (웹 상세 화면에도 점수 배지가 뜨지 않는 이유입니다.)
class PlaceDetail {
  const PlaceDetail({
    required this.id,
    required this.name,
    required this.type,
    required this.typeLabel,
    required this.address,
    required this.lat,
    required this.lng,
    required this.priceLevel,
    required this.priceLabel,
    required this.indoor,
    required this.outdoor,
    required this.stayMinutesMin,
    required this.stayMinutesMax,
    required this.openStatusLabel,
    required this.scores,
    required this.weatherScores,
    required this.warnings,
    required this.tags,
    required this.themes,
    required this.saved,
    required this.userCreated,
    required this.reviewCount,
    required this.reviews,
    this.estimatedCostMin,
    this.estimatedCostMax,
    this.openingHoursText,
    this.description,
    this.source,
    this.sourceUrl,
    this.createdByUsername,
    this.averageRating,
  });

  final int id;
  final String name;

  /// 서버 `PlaceType` 이름. 수정 폼의 선택값을 되살리는 데 씁니다.
  final String type;

  final String typeLabel;
  final String address;
  final double lat;
  final double lng;

  /// 서버 `PriceLevel` 이름. 수정 폼의 선택값을 되살리는 데 씁니다.
  final String priceLevel;

  final String priceLabel;
  final bool indoor;
  final bool outdoor;
  final int stayMinutesMin;
  final int stayMinutesMax;

  /// 서버 `OperatingStatus`의 한글 라벨 (영업중 / 휴게시간 / 영업종료).
  final String openStatusLabel;

  final PlaceFacilityScores scores;
  final PlaceWeatherScores weatherScores;
  final List<String> warnings;
  final List<String> tags;

  /// 서버 `PlaceTheme` 이름 목록. 수정 폼에서 되살립니다.
  final List<String> themes;

  /// 로그인한 사용자가 저장한 장소인지. 비로그인이면 서버가 항상 `false`를 줍니다.
  final bool saved;

  final bool userCreated;
  final int reviewCount;

  /// 최신순으로 서버가 정렬해 줍니다. (`findByPlaceIdOrderByCreatedAtDesc`)
  final List<PlaceReview> reviews;
  final int? estimatedCostMin;
  final int? estimatedCostMax;
  final String? openingHoursText;
  final String? description;
  final String? source;
  final String? sourceUrl;
  final String? createdByUsername;
  final double? averageRating;

  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    return PlaceDetail(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      type: json['type'] as String? ?? '',
      typeLabel: json['typeLabel'] as String? ?? '',
      address: json['address'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      priceLevel: json['priceLevel'] as String? ?? '',
      priceLabel: json['priceLabel'] as String? ?? '',
      indoor: json['indoor'] as bool? ?? false,
      outdoor: json['outdoor'] as bool? ?? false,
      stayMinutesMin: (json['stayMinutesMin'] as num?)?.round() ?? 0,
      stayMinutesMax: (json['stayMinutesMax'] as num?)?.round() ?? 0,
      openStatusLabel: json['openStatusLabel'] as String? ?? '',
      scores: PlaceFacilityScores.fromJson(
        json['scores'] as Map<String, dynamic>?,
      ),
      weatherScores: PlaceWeatherScores.fromJson(
        json['weatherScores'] as Map<String, dynamic>?,
      ),
      warnings: _stringList(json['warnings']),
      tags: _stringList(json['tags']),
      themes: _stringList(json['themes']),
      saved: json['saved'] as bool? ?? false,
      userCreated: json['userCreated'] as bool? ?? false,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      reviews: _reviewList(json['reviews']),
      estimatedCostMin: (json['estimatedCostMin'] as num?)?.toInt(),
      estimatedCostMax: (json['estimatedCostMax'] as num?)?.toInt(),
      openingHoursText: _trimmedOrNull(json['openingHoursText']),
      description: _trimmedOrNull(json['description']),
      source: _trimmedOrNull(json['source']),
      sourceUrl: _trimmedOrNull(json['sourceUrl']),
      createdByUsername: _trimmedOrNull(json['createdByUsername']),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
    );
  }

  /// 후기가 하나도 없으면 서버가 평균을 `null`로 줍니다. 이때는 별점을 숨깁니다.
  bool get hasRating => reviewCount > 0 && averageRating != null;

  String get costLabel =>
      PlaceFormat.cost(estimatedCostMin, estimatedCostMax, priceLabel);

  String get spaceLabel =>
      PlaceFormat.space(indoor: indoor, outdoor: outdoor);

  String get stayLabel =>
      PlaceFormat.stayRange(stayMinutesMin, stayMinutesMax);

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return const [];
  }

  static List<PlaceReview> _reviewList(Object? value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(PlaceReview.fromJson)
          .toList(growable: false);
    }
    return const [];
  }

  /// 서버가 빈 문자열을 주는 필드가 있어 `null`과 같게 취급합니다.
  static String? _trimmedOrNull(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

int _score(Object? value) {
  final score = (value as num?)?.round() ?? 0;
  return score.clamp(0, 5);
}
