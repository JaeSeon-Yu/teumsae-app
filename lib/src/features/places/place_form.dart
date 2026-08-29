import '../../core/config/app_config.dart';
import 'place_detail.dart';

/// 장소 유형. 서버 `PlaceType` 중 사용자가 고를 수 있는 것만 둡니다.
///
/// 웹 `PLACE_TYPE_OPTIONS`와 같은 구성입니다. `TRADITIONAL_MARKET`과
/// `LARGE_SCALE_RETAIL`은 공공데이터 동기화로만 들어오므로 제외합니다.
enum PlaceTypeOption {
  library('LIBRARY', '도서관'),
  publicFacility('PUBLIC_FACILITY', '공공시설'),
  publicToilet('PUBLIC_TOILET', '공중화장실'),
  shelter('SHELTER', '쉼터'),
  park('PARK', '공원'),
  subwayStation('SUBWAY_STATION', '지하철역'),
  undergroundMall('UNDERGROUND_MALL', '지하상가'),
  cafe('CAFE', '카페'),
  fastfood('FASTFOOD', '패스트푸드'),
  studyCafe('STUDY_CAFE', '스터디카페'),
  pcCafe('PC_CAFE', 'PC방'),
  mangaCafe('MANGA_CAFE', '만화카페'),
  ;

  const PlaceTypeOption(this.value, this.label);

  final String value;
  final String label;

  /// 서버가 준 값이 목록에 없으면(동기화 전용 유형) 기본값으로 둡니다.
  static PlaceTypeOption fromValue(String? value) => values.firstWhere(
        (option) => option.value == value,
        orElse: () => PlaceTypeOption.publicFacility,
      );
}

/// 서버 `PriceLevel`. 라벨은 웹 `PRICE_LEVEL_OPTIONS`와 같습니다.
enum PriceLevelOption {
  free('FREE', '무료'),
  under2000('UNDER_2000', '2000원 이하'),
  under4000('UNDER_4000', '4000원 이하'),
  under6000('UNDER_6000', '6000원 이하'),
  over6000('OVER_6000', '6000원 초과'),
  ;

  const PriceLevelOption(this.value, this.label);

  final String value;
  final String label;

  static PriceLevelOption fromValue(String? value) => values.firstWhere(
        (option) => option.value == value,
        orElse: () => PriceLevelOption.free,
      );
}

/// 등록·수정에서 직접 고를 수 있는 테마. 웹 `USER_SELECTABLE_THEMES`와 같습니다.
///
/// `ANY`는 검색 필터 전용이고 `TOILET`은 공공데이터 유형에서 파생되므로 빼둡니다.
enum PlaceThemeOption {
  rest('REST', '휴식'),
  shopping('SHOPPING', '쇼핑'),
  play('PLAY', '즐길거리'),
  ;

  const PlaceThemeOption(this.value, this.label);

  final String value;
  final String label;

  static PlaceThemeOption? fromValue(String value) {
    for (final option in values) {
      if (option.value == value) return option;
    }
    return null;
  }
}

/// 운영시간 입력 방식. 웹 `OpeningHoursMode`와 같습니다.
///
/// 웹은 요일 그룹까지 만들 수 있지만(`OperatingHoursForm`) 앱은 세 가지만 둡니다.
/// 좁은 화면에서 요일별 규칙을 짜는 UI는 입력 부담이 커서, 우선 서버·웹이 모두
/// 읽을 수 있는 형태만 만들고 필요해지면 늘립니다.
enum OpeningHoursMode {
  range('시간 범위'),
  allDay('24시간'),
  custom('직접 입력'),
  ;

  const OpeningHoursMode(this.label);

  final String label;
}

/// 등록·수정 폼 상태. 웹 `PlaceFormValues`에 대응합니다.
///
/// 비용은 문자열로 들고 있습니다. 입력 중에는 비어 있을 수 있고("상관없음"),
/// 숫자로 바꾸는 시점을 제출 직전으로 미뤄야 지우는 중에 0으로 튀지 않습니다.
class PlaceFormValues {
  const PlaceFormValues({
    this.name = '',
    this.type = PlaceTypeOption.publicFacility,
    this.address = '',
    this.lat = DefaultSearchParams.lat,
    this.lng = DefaultSearchParams.lng,
    this.indoor = true,
    this.outdoor = false,
    this.priceLevel = PriceLevelOption.free,
    this.estimatedCostMin = '0',
    this.estimatedCostMax = '0',
    this.stayMinutesMin = 15,
    this.stayMinutesMax = 60,
    this.seating = true,
    this.wifi = false,
    this.toilet = false,
    this.charging = false,
    this.quiet = false,
    this.laptop = false,
    this.tags = const {},
    this.themes = const {},
    this.openingHoursMode = OpeningHoursMode.range,
    this.openingHoursStart = '09:00',
    this.openingHoursEnd = '18:00',
    this.openingHoursCustom = '',
    this.description = '',
  });

  final String name;
  final PlaceTypeOption type;

  /// 비우면 서버가 좌표로 주소를 찾아 채웁니다. 못 찾으면 400을 줍니다.
  final String address;

  final double lat;
  final double lng;
  final bool indoor;
  final bool outdoor;
  final PriceLevelOption priceLevel;
  final String estimatedCostMin;
  final String estimatedCostMax;
  final int stayMinutesMin;
  final int stayMinutesMax;
  final bool seating;
  final bool wifi;
  final bool toilet;
  final bool charging;
  final bool quiet;
  final bool laptop;

  /// 서버가 아는 태그 라벨만 보낼 수 있습니다. (`GET /api/places/tags`)
  final Set<String> tags;

  final Set<PlaceThemeOption> themes;
  final OpeningHoursMode openingHoursMode;
  final String openingHoursStart;
  final String openingHoursEnd;
  final String openingHoursCustom;
  final String description;

  /// 서버 `CreatePlaceRequest`의 제약. 한쪽만 바꾸면 앱은 통과하고 서버가 400을 줍니다.
  static const maxNameLength = 80;
  static const maxAddressLength = 255;
  static const maxDescriptionLength = 1000;
  static const maxOpeningHoursLength = 255;
  static const maxTagCount = 8;
  static const minStayMinutes = 1;
  static const maxStayMinutes = 1440;
  static const maxCost = 1000000;

  /// 실내·실외를 함께 다루는 태그. 고르면 플래그도 같이 움직입니다.
  static const indoorTag = '실내';
  static const outdoorTag = '실외';

  /// 편의시설 태그와 플래그의 대응. 웹 `featurePatchFromTags`와 같습니다.
  static const featureTags = <String, String>{
    '좌석': 'seating',
    '와이파이': 'wifi',
    '화장실': 'toilet',
    '충전': 'charging',
    '조용함': 'quiet',
    '노트북': 'laptop',
  };

  PlaceFormValues copyWith({
    String? name,
    PlaceTypeOption? type,
    String? address,
    double? lat,
    double? lng,
    bool? indoor,
    bool? outdoor,
    PriceLevelOption? priceLevel,
    String? estimatedCostMin,
    String? estimatedCostMax,
    int? stayMinutesMin,
    int? stayMinutesMax,
    bool? seating,
    bool? wifi,
    bool? toilet,
    bool? charging,
    bool? quiet,
    bool? laptop,
    Set<String>? tags,
    Set<PlaceThemeOption>? themes,
    OpeningHoursMode? openingHoursMode,
    String? openingHoursStart,
    String? openingHoursEnd,
    String? openingHoursCustom,
    String? description,
  }) {
    return PlaceFormValues(
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      indoor: indoor ?? this.indoor,
      outdoor: outdoor ?? this.outdoor,
      priceLevel: priceLevel ?? this.priceLevel,
      estimatedCostMin: estimatedCostMin ?? this.estimatedCostMin,
      estimatedCostMax: estimatedCostMax ?? this.estimatedCostMax,
      stayMinutesMin: stayMinutesMin ?? this.stayMinutesMin,
      stayMinutesMax: stayMinutesMax ?? this.stayMinutesMax,
      seating: seating ?? this.seating,
      wifi: wifi ?? this.wifi,
      toilet: toilet ?? this.toilet,
      charging: charging ?? this.charging,
      quiet: quiet ?? this.quiet,
      laptop: laptop ?? this.laptop,
      tags: tags ?? this.tags,
      themes: themes ?? this.themes,
      openingHoursMode: openingHoursMode ?? this.openingHoursMode,
      openingHoursStart: openingHoursStart ?? this.openingHoursStart,
      openingHoursEnd: openingHoursEnd ?? this.openingHoursEnd,
      openingHoursCustom: openingHoursCustom ?? this.openingHoursCustom,
      description: description ?? this.description,
    );
  }

  /// 수정 폼의 초기값. 웹 `placeFormValuesFromDetail`과 같은 규칙입니다.
  ///
  /// 서버는 편의시설을 0~5점으로 들고 있어서 2점 이상을 "선택됨"으로 봅니다.
  /// (웹 `FEATURE_TAG_THRESHOLD`)
  factory PlaceFormValues.fromDetail(PlaceDetail place) {
    const threshold = 2;
    final scores = place.scores;

    final seating = scores.seating >= threshold;
    final wifi = scores.wifi >= threshold;
    final toilet = scores.toilet >= threshold;
    final charging = scores.charging >= threshold;
    final quiet = scores.quiet >= threshold;
    final laptop = scores.laptop >= threshold;

    // 서버가 준 태그에 실내·실외·편의시설을 더해 화면 선택 상태를 맞춥니다.
    final tags = {
      ...place.tags,
      if (place.indoor) indoorTag,
      if (place.outdoor) outdoorTag,
      if (seating) '좌석',
      if (wifi) '와이파이',
      if (toilet) '화장실',
      if (charging) '충전',
      if (quiet) '조용함',
      if (laptop) '노트북',
    };

    final hours = _parseOpeningHours(place.openingHoursText ?? '');

    return PlaceFormValues(
      name: place.name,
      type: PlaceTypeOption.fromValue(place.type),
      address: place.address,
      lat: place.lat,
      lng: place.lng,
      indoor: place.indoor,
      outdoor: place.outdoor,
      priceLevel: PriceLevelOption.fromValue(place.priceLevel),
      estimatedCostMin: place.estimatedCostMin?.toString() ?? '',
      estimatedCostMax: place.estimatedCostMax?.toString() ?? '',
      stayMinutesMin: place.stayMinutesMin,
      stayMinutesMax: place.stayMinutesMax,
      seating: seating,
      wifi: wifi,
      toilet: toilet,
      charging: charging,
      quiet: quiet,
      laptop: laptop,
      tags: tags,
      themes: place.themes
          .map(PlaceThemeOption.fromValue)
          .whereType<PlaceThemeOption>()
          .toSet(),
      openingHoursMode: hours.mode,
      openingHoursStart: hours.start,
      openingHoursEnd: hours.end,
      openingHoursCustom: hours.custom,
      description: place.description ?? '',
    );
  }

  /// 태그를 고치면 실내·실외와 편의시설 플래그도 함께 맞춥니다.
  /// 웹 `featurePatchFromTags`와 같습니다.
  PlaceFormValues withTags(Set<String> next) {
    return copyWith(
      tags: next,
      // 실외만 고른 경우를 빼면 실내로 봅니다. 서버가 둘 중 하나를 요구합니다.
      indoor: next.contains(indoorTag) || !next.contains(outdoorTag),
      outdoor: next.contains(outdoorTag),
      seating: next.contains('좌석'),
      wifi: next.contains('와이파이'),
      toilet: next.contains('화장실'),
      charging: next.contains('충전'),
      quiet: next.contains('조용함'),
      laptop: next.contains('노트북'),
    );
  }

  /// 통과하면 `null`, 아니면 화면에 그대로 띄울 한글 문구.
  /// 문구는 웹 `validatePlaceFormValues`와 같게 맞췄습니다.
  String? validate() {
    if (name.trim().isEmpty) {
      return '장소 이름을 입력해 주세요.';
    }
    if (name.trim().length > maxNameLength) {
      return '장소 이름은 $maxNameLength자 이하로 입력해 주세요.';
    }
    if (!indoor && !outdoor) {
      return '실내 또는 실외 중 하나는 선택해야 합니다.';
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return '지도 위치 좌표가 올바르지 않습니다.';
    }
    if (stayMinutesMin < minStayMinutes ||
        stayMinutesMin > maxStayMinutes ||
        stayMinutesMax < minStayMinutes ||
        stayMinutesMax > maxStayMinutes) {
      return '체류 시간은 $minStayMinutes분부터 $maxStayMinutes분까지 입력할 수 있습니다.';
    }
    if (stayMinutesMin > stayMinutesMax) {
      return '최소 체류 시간은 최대 체류 시간보다 클 수 없습니다.';
    }

    final min = _costOrNull(estimatedCostMin);
    final max = _costOrNull(estimatedCostMax);
    if (!_isValidCost(estimatedCostMin) || !_isValidCost(estimatedCostMax)) {
      return '비용은 0원부터 1,000,000원까지 숫자로 입력해 주세요.';
    }
    if (min != null && max != null && min > max) {
      return '최소 비용은 최대 비용보다 클 수 없습니다.';
    }

    if (address.trim().length > maxAddressLength) {
      return '주소는 $maxAddressLength자 이하로 입력해 주세요.';
    }
    if (description.trim().length > maxDescriptionLength) {
      return '설명은 $maxDescriptionLength자 이하로 입력해 주세요.';
    }
    if (tags.length > maxTagCount) {
      return '태그는 $maxTagCount개까지 고를 수 있습니다.';
    }

    final hours = openingHoursText;
    if (hours != null && hours.length > maxOpeningHoursLength) {
      return '운영시간은 $maxOpeningHoursLength자 이하로 입력해 주세요.';
    }

    return null;
  }

  /// 선택한 방식에 따라 서버에 보낼 운영시간 문자열. 비우면 `null`.
  String? get openingHoursText {
    switch (openingHoursMode) {
      case OpeningHoursMode.allDay:
        // 서버·웹이 모두 "종일"을 24시간으로 읽습니다.
        return '종일';
      case OpeningHoursMode.range:
        return '$openingHoursStart-$openingHoursEnd';
      case OpeningHoursMode.custom:
        final trimmed = openingHoursCustom.trim();
        return trimmed.isEmpty ? null : trimmed;
    }
  }

  /// `POST /api/places` · `PUT /api/places/{id}` 본문.
  Map<String, dynamic> toRequestBody() {
    return {
      'name': name.trim(),
      'type': type.value,
      // 비우면 서버가 좌표로 주소를 찾습니다. 빈 문자열이 아니라 null로 보냅니다.
      'address': address.trim().isEmpty ? null : address.trim(),
      'lat': lat,
      'lng': lng,
      'indoor': indoor,
      'outdoor': outdoor,
      'priceLevel': priceLevel.value,
      'estimatedCostMin': _costOrNull(estimatedCostMin),
      'estimatedCostMax': _costOrNull(estimatedCostMax),
      'stayMinutesMin': stayMinutesMin,
      'stayMinutesMax': stayMinutesMax,
      'seating': seating,
      'wifi': wifi,
      'toilet': toilet,
      'charging': charging,
      'quiet': quiet,
      'laptop': laptop,
      'themes': themes.map((theme) => theme.value).toList(growable: false),
      'tags': tags.toList(growable: false),
      'openingHoursText': openingHoursText,
      'description':
          description.trim().isEmpty ? null : description.trim(),
    };
  }

  static int? _costOrNull(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return int.tryParse(trimmed);
  }

  static bool _isValidCost(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return true;
    }
    final parsed = int.tryParse(trimmed);
    return parsed != null && parsed >= 0 && parsed <= maxCost;
  }

  /// 저장된 운영시간 문자열을 입력 상태로 되돌립니다. 웹 `parseOpeningHours`와 같습니다.
  static ({
    OpeningHoursMode mode,
    String start,
    String end,
    String custom,
  }) _parseOpeningHours(String raw) {
    if (raw == '종일' || raw == '24시간') {
      return (
        mode: OpeningHoursMode.allDay,
        start: '09:00',
        end: '18:00',
        custom: '',
      );
    }

    final range = RegExp(r'^(\d{2}:\d{2})-(\d{2}:\d{2})$').firstMatch(raw);
    if (range != null) {
      return (
        mode: OpeningHoursMode.range,
        start: range.group(1)!,
        end: range.group(2)!,
        custom: '',
      );
    }

    return (
      mode: raw.trim().isEmpty
          ? OpeningHoursMode.range
          : OpeningHoursMode.custom,
      start: '09:00',
      end: '18:00',
      custom: raw,
    );
  }
}

/// 서버가 허용하는 태그. `GET /api/places/tags`가 이름과 라벨을 줍니다.
/// 보낼 때는 라벨을 씁니다. (`PlaceTag.fromLabel`)
class PlaceTagOption {
  const PlaceTagOption({required this.name, required this.label});

  final String name;
  final String label;

  factory PlaceTagOption.fromJson(Map<String, dynamic> json) {
    return PlaceTagOption(
      name: json['name'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }
}
