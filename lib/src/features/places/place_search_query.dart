import '../../core/config/app_config.dart';

/// 검색 테마. 서버 `PlaceTheme`, 라벨은 웹 `THEME_CONFIG`와 같습니다.
enum SearchTheme {
  any('ANY', '전체'),
  rest('REST', '휴식'),
  shopping('SHOPPING', '쇼핑'),
  play('PLAY', '즐길거리'),
  toilet('TOILET', '화장실'),
  ;

  const SearchTheme(this.value, this.label);

  final String value;
  final String label;

  static SearchTheme fromValue(String value) => values.firstWhere(
        (theme) => theme.value == value,
        orElse: () => SearchTheme.any,
      );
}

/// 서버 `BudgetFilter`. 라벨은 웹 `SearchFilters`의 `budgetOptions`와 같습니다.
enum SearchBudget {
  any('ANY', '상관없음'),
  free('FREE', '무료'),
  under2000('UNDER_2000', '2천원 이하'),
  under4000('UNDER_4000', '4천원 이하'),
  under6000('UNDER_6000', '6천원 이하'),
  over6000('OVER_6000', '6천원 초과'),
  ;

  const SearchBudget(this.value, this.label);

  final String value;
  final String label;
}

/// 서버 `SpacePreference`.
enum SearchSpace {
  any('ANY', '상관없음'),
  indoor('INDOOR', '실내'),
  outdoor('OUTDOOR', '실외'),
  ;

  const SearchSpace(this.value, this.label);

  final String value;
  final String label;
}

/// 서버 `NeedType`. 값은 대소문자를 가리지 않지만(`parseEnum`) 웹과 같게 소문자로 보냅니다.
///
/// 서버에는 `LONG_STAY`도 있으나 웹 필터에 없어서 앱에도 넣지 않았습니다.
/// (체류 시간은 "남은 시간"으로 이미 다루고 있습니다)
enum SearchNeed {
  seating('seating', '앉을 수 있음'),
  wifi('wifi', '와이파이'),
  toilet('toilet', '화장실'),
  charging('charging', '충전 가능'),
  quiet('quiet', '조용함'),
  laptop('laptop', '노트북 가능'),
  ;

  const SearchNeed(this.value, this.label);

  final String value;
  final String label;
}

/// 서버 `PlaceSort`.
enum SearchSort {
  recommended('recommended', '추천순'),
  distance('distance', '가까운순'),
  ;

  const SearchSort(this.value, this.label);

  final String value;
  final String label;
}

/// 검색 조건. 서버 `PlaceSearchRequest`의 허용 범위를 그대로 따릅니다.
class PlaceSearchQuery {
  const PlaceSearchQuery({
    this.lat = DefaultSearchParams.lat,
    this.lng = DefaultSearchParams.lng,
    this.radius = DefaultSearchParams.radius,
    this.stayMinutes = DefaultSearchParams.stayMinutes,
    // 웹 `DEFAULT_SEARCH_PARAMS.theme`과 같은 기본값입니다.
    this.theme = SearchTheme.rest,
    this.budget = SearchBudget.any,
    this.space = SearchSpace.any,
    this.needs = const {},
    this.sort = SearchSort.recommended,
    this.openOnly = DefaultSearchParams.openOnly,
  });

  final double lat;
  final double lng;

  /// 100~5000 (서버가 범위를 벗어나면 400을 반환합니다)
  final int radius;

  /// 0~360. 0은 "상관없음"입니다.
  final int stayMinutes;

  final SearchTheme theme;
  final SearchBudget budget;
  final SearchSpace space;

  /// 모두 만족하는 장소만 찾습니다.
  final Set<SearchNeed> needs;

  final SearchSort sort;
  final bool openOnly;

  /// 선택할 수 있는 반경. 웹에는 반경 UI가 없지만 앱에는 아직 지도가 없어서
  /// 범위를 넓힐 방법이 필요합니다.
  static const radiusOptions = <int>[500, 1000, 1500, 3000, 5000];

  /// 남은 시간 선택값. 웹 `stayOptions`와 같습니다. 0은 "상관없음".
  static const stayMinutesOptions = <int>[0, 15, 30, 60, 120];

  PlaceSearchQuery copyWith({
    double? lat,
    double? lng,
    int? radius,
    int? stayMinutes,
    SearchTheme? theme,
    SearchBudget? budget,
    SearchSpace? space,
    Set<SearchNeed>? needs,
    SearchSort? sort,
    bool? openOnly,
  }) {
    return PlaceSearchQuery(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radius: radius ?? this.radius,
      stayMinutes: stayMinutes ?? this.stayMinutes,
      theme: theme ?? this.theme,
      budget: budget ?? this.budget,
      space: space ?? this.space,
      needs: needs ?? this.needs,
      sort: sort ?? this.sort,
      openOnly: openOnly ?? this.openOnly,
    );
  }

  /// 조건 시트에서 되돌릴 수 있는 항목만 기본값으로 되돌립니다.
  /// (테마·정렬·영업중은 시트 밖에 있어 그대로 둡니다)
  PlaceSearchQuery resetFilters() {
    return copyWith(
      radius: DefaultSearchParams.radius,
      stayMinutes: DefaultSearchParams.stayMinutes,
      budget: SearchBudget.any,
      space: SearchSpace.any,
      needs: const {},
    );
  }

  /// 조건 버튼에 표시할 활성 개수. 웹 `activeCount`에 반경을 더한 값입니다.
  int get activeFilterCount =>
      (stayMinutes != DefaultSearchParams.stayMinutes ? 1 : 0) +
      (radius != DefaultSearchParams.radius ? 1 : 0) +
      (space != SearchSpace.any ? 1 : 0) +
      (budget != SearchBudget.any ? 1 : 0) +
      needs.length;

  Map<String, dynamic> toQueryParameters() {
    return {
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'stayMinutes': stayMinutes,
      'budget': budget.value,
      // 웹에도 날씨 선택 UI가 없습니다. 서버 기본값과 같은 ANY로 보냅니다.
      'weather': DefaultSearchParams.weather,
      'space': space.value,
      'needs': needs.map((need) => need.value).join(','),
      'sort': sort.value,
      'theme': theme.value,
      'openOnly': openOnly,
    };
  }
}
