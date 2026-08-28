import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import 'place_search_query.dart';
import 'place_summary.dart';
import 'places_repository.dart';

/// 검색 화면 상태. 화면이 열릴 때 [ShellBinding]이 등록합니다.
class PlacesController extends GetxController {
  PlacesController(this._repository);

  final PlacesRepository _repository;

  final _query = const PlaceSearchQuery().obs;
  final _places = <PlaceSummary>[].obs;
  final _isLoading = false.obs;
  final _errorMessage = RxnString();

  PlaceSearchQuery get query => _query.value;
  List<PlaceSummary> get places => _places;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;

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

  Future<void> _apply(PlaceSearchQuery query) {
    _query.value = query;
    return search();
  }
}
