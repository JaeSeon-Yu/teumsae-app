import 'package:get/get.dart';

import '../../core/config/app_config.dart';
import '../../core/location/location_service.dart';
import '../../core/network/api_exception.dart';
import 'place_search_query.dart';
import 'place_summary.dart';
import 'places_repository.dart';

/// 검색 화면 상태. 화면이 열릴 때 [ShellBinding]이 등록합니다.
class PlacesController extends GetxController {
  PlacesController({required PlacesRepository repository,
    required LocationService location,
  })  : _repository = repository,
        _location = location;

  final PlacesRepository _repository;
  final LocationService _location;

  final _query = const PlaceSearchQuery().obs;
  final _places = <PlaceSummary>[].obs;
  final _isLoading = false.obs;
  final _errorMessage = RxnString();

  final _isLocating = false.obs;
  final _locationError = RxnString();
  final _usingCurrentLocation = false.obs;

  PlaceSearchQuery get query => _query.value;
  List<PlaceSummary> get places => _places;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;

  /// 현재 위치를 가져오는 중인지. 버튼을 잠그고 진행 표시를 띄우는 데 씁니다.
  bool get isLocating => _isLocating.value;

  /// 위치 조회 실패 문구. 검색 결과는 그대로 남으므로 [errorMessage]와 따로 둡니다.
  String? get locationError => _locationError.value;

  /// 지금 검색에 쓰는 좌표가 현재 위치인지. 기본 좌표면 `false`입니다.
  bool get usingCurrentLocation => _usingCurrentLocation.value;

  @override
  void onInit() {
    super.onInit();
    search();
  }

  Future<void> search() async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      _places.assignAll(await _repository.search(_query.value));
    } on ApiException catch (error) {
      _places.clear();
      _errorMessage.value = error.message;
    } on Object {
      _places.clear();
      _errorMessage.value = '검색 결과를 불러오지 못했습니다.';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> changeTheme(SearchTheme theme) {
    if (_query.value.theme == theme) {
      return Future.value();
    }
    return _apply(_query.value.copyWith(theme: theme));
  }

  Future<void> changeSort(SearchSort sort) {
    if (_query.value.sort == sort) {
      return Future.value();
    }
    return _apply(_query.value.copyWith(sort: sort));
  }

  Future<void> toggleOpenOnly() {
    return _apply(_query.value.copyWith(openOnly: !_query.value.openOnly));
  }

  /// 조건 시트에서 만든 조건을 한 번에 적용합니다.
  ///
  /// 항목을 고를 때마다 검색하면 요청이 여러 번 나가고 결과가 계속 흔들립니다.
  /// 그래서 시트 안에서는 초안만 들고 있다가 "조건 적용"에서 이 메서드를 부릅니다.
  Future<void> applyFilters(PlaceSearchQuery query) => _apply(query);

  /// 현재 위치로 좌표를 바꾸고 다시 검색합니다.
  ///
  /// 실패하면 좌표를 그대로 두고 [locationError]만 채웁니다. 이미 보고 있던
  /// 검색 결과를 지우면 권한을 거부한 사용자가 아무것도 볼 수 없게 됩니다.
  Future<void> useCurrentLocation() async {
    if (_isLocating.value) {
      return;
    }

    _isLocating.value = true;
    _locationError.value = null;

    try {
      final location = await _location.current();
      _usingCurrentLocation.value = true;
      await _apply(
        _query.value.copyWith(lat: location.lat, lng: location.lng),
      );
    } on LocationException catch (error) {
      _locationError.value = error.message;
    } on Object {
      _locationError.value = LocationFailure.unavailable.message;
    } finally {
      _isLocating.value = false;
    }
  }

  /// 기본 좌표로 되돌리고 다시 검색합니다. 이미 기본 좌표면 검색하지 않습니다.
  Future<void> useDefaultLocation() async {
    _locationError.value = null;

    if (!_usingCurrentLocation.value) {
      return;
    }

    _usingCurrentLocation.value = false;
    await _apply(
      _query.value.copyWith(
        lat: DefaultSearchParams.lat,
        lng: DefaultSearchParams.lng,
      ),
    );
  }

  /// 위치 실패 문구를 화면에서 한 번 보여 준 뒤 지웁니다.
  void clearLocationError() => _locationError.value = null;

  Future<void> _apply(PlaceSearchQuery query) {
    _query.value = query;
    return search();
  }
}
