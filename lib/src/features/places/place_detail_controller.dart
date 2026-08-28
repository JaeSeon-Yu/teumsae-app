import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import 'place_detail.dart';
import 'places_repository.dart';

/// 장소 상세 화면 상태. [PlaceDetailBinding]이 라우트 진입 시 등록합니다.
///
/// 장소 id는 라우트 파라미터(`/places/:id`)로 받습니다.
class PlaceDetailController extends GetxController {
  PlaceDetailController({required PlacesRepository repository, required this.id})
      : _repository = repository;

  final PlacesRepository _repository;
  final int id;

  final _place = Rxn<PlaceDetail>();
  final _isLoading = true.obs;
  final _errorMessage = RxnString();

  PlaceDetail? get place => _place.value;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      _place.value = await _repository.getPlace(id);
    } on ApiException catch (error) {
      _place.value = null;
      // 404는 서버 메시지가 영문일 수 있어 화면 문구를 따로 둡니다.
      _errorMessage.value =
          error.statusCode == 404 ? '없는 장소이거나 삭제된 장소입니다.' : error.message;
    } on Object {
      _place.value = null;
      _errorMessage.value = '장소 정보를 불러오지 못했습니다.';
    } finally {
      _isLoading.value = false;
    }
  }
}
