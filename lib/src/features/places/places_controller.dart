import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import 'place_summary.dart';
import 'places_repository.dart';

/// 검색 화면 상태. 화면이 열릴 때 [PlacesBinding]이 등록합니다.
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

  Future<void> changeTheme(String theme) {
    if (_query.value.theme == theme) {
      return Future.value();
    }
    _query.value = _query.value.copyWith(theme: theme);
    return search();
  }

  Future<void> changeRadius(int radius) {
    _query.value = _query.value.copyWith(radius: radius);
    return search();
  }
}
