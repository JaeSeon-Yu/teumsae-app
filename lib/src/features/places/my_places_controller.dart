import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import 'place_detail.dart';
import 'places_repository.dart';

/// 내가 등록한 장소 목록. [MyPlacesBinding]이 라우트 진입 시 등록합니다.
class MyPlacesController extends GetxController {
  MyPlacesController(this._repository);

  final PlacesRepository _repository;

  final _places = <PlaceDetail>[].obs;
  final _isLoading = true.obs;
  final _errorMessage = RxnString();
  final _deletingId = RxnInt();

  List<PlaceDetail> get places => _places;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;

  /// 삭제 중인 장소 id. 그 항목의 버튼만 잠그는 데 씁니다.
  int? get deletingId => _deletingId.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      _places.assignAll(await _repository.myPlaces());
    } on ApiException catch (error) {
      _places.clear();
      _errorMessage.value = error.message;
    } on Object {
      _places.clear();
      _errorMessage.value = '등록한 장소를 불러오지 못했습니다.';
    } finally {
      _isLoading.value = false;
    }
  }

  /// 성공하면 `true`. 목록에서 지우고 서버를 다시 부르지 않습니다.
  /// (삭제는 결과가 명확해서 다시 받아올 이유가 없습니다)
  Future<bool> delete(int id) async {
    if (_deletingId.value != null) {
      return false;
    }

    _deletingId.value = id;
    _errorMessage.value = null;

    try {
      await _repository.deletePlace(id);
      _places.removeWhere((place) => place.id == id);
      return true;
    } on ApiException catch (error) {
      _errorMessage.value = error.message;
      return false;
    } on Object {
      _errorMessage.value = '장소를 삭제하지 못했습니다.';
      return false;
    } finally {
      _deletingId.value = null;
    }
  }
}
