import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import 'place_detail.dart';
import 'place_form.dart';
import 'places_repository.dart';

/// 장소 등록·수정 폼 상태. [PlaceFormBinding]이 라우트 진입 시 등록합니다.
///
/// [placeId]가 `null`이면 등록, 있으면 수정입니다.
class PlaceFormController extends GetxController {
  PlaceFormController({required PlacesRepository repository, this.placeId})
      : _repository = repository;

  final PlacesRepository _repository;

  /// 수정할 장소 id. 등록이면 `null`.
  final int? placeId;

  final _values = const PlaceFormValues().obs;
  final _tagOptions = <PlaceTagOption>[].obs;
  final _isLoading = false.obs;
  final _isSubmitting = false.obs;
  final _errorMessage = RxnString();
  final _isResolvingAddress = false.obs;

  PlaceFormValues get values => _values.value;
  List<PlaceTagOption> get tagOptions => _tagOptions;

  /// 주소가 서버 역지오코딩으로 채워지는 것을 화면 입력칸이 따라가야 해서 엽니다.
  /// `Rx` 자체를 공개하면 밖에서 값을 바꿀 수 있어 읽기 전용 스트림만 냅니다.
  /// (`AuthController.userChanges`와 같은 방식)
  Stream<PlaceFormValues> get valueChanges => _values.stream;

  /// 수정 폼이 기존 값을 불러오는 중.
  bool get isLoading => _isLoading.value;

  bool get isSubmitting => _isSubmitting.value;
  String? get errorMessage => _errorMessage.value;

  /// 핀을 옮긴 뒤 주소를 찾는 중.
  bool get isResolvingAddress => _isResolvingAddress.value;

  bool get isEditing => placeId != null;
  String get title => isEditing ? '장소 수정' : '장소 등록';

  @override
  void onInit() {
    super.onInit();
    _loadTags();
    if (isEditing) {
      loadPlace();
    }
  }

  /// 태그는 서버가 아는 라벨만 보낼 수 있어서 목록을 받아 옵니다.
  /// 실패하면 태그 없이도 등록할 수 있게 조용히 넘어갑니다.
  Future<void> _loadTags() async {
    try {
      _tagOptions.assignAll(await _repository.tags());
    } on Object {
      _tagOptions.clear();
    }
  }

  Future<void> loadPlace() async {
    final id = placeId;
    if (id == null) {
      return;
    }

    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      _values.value = PlaceFormValues.fromDetail(
        await _repository.getPlace(id),
      );
    } on ApiException catch (error) {
      _errorMessage.value =
          error.statusCode == 404 ? '없는 장소이거나 삭제된 장소입니다.' : error.message;
    } on Object {
      _errorMessage.value = '장소 정보를 불러오지 못했습니다.';
    } finally {
      _isLoading.value = false;
    }
  }

  void updateValues(PlaceFormValues next) => _values.value = next;

  /// 태그를 켜고 끕니다. 실내·실외와 편의시설 플래그도 함께 움직입니다.
  void toggleTag(String label) {
    final next = {...values.tags};
    if (!next.remove(label)) {
      if (next.length >= PlaceFormValues.maxTagCount) {
        _errorMessage.value =
            '태그는 ${PlaceFormValues.maxTagCount}개까지 고를 수 있습니다.';
        return;
      }
      next.add(label);
    }

    _errorMessage.value = null;
    _values.value = values.withTags(next);
  }

  void toggleTheme(PlaceThemeOption theme) {
    final next = {...values.themes};
    if (!next.remove(theme)) {
      next.add(theme);
    }
    _values.value = values.copyWith(themes: next);
  }

  /// 지도에서 핀을 옮기면 좌표를 바꾸고 주소를 다시 찾습니다.
  ///
  /// 주소를 직접 적어 둔 경우에는 덮어쓰지 않습니다. 사용자가 적은 값을
  /// 지우면 왜 바뀌었는지 알 수 없습니다.
  Future<void> movePin(double lat, double lng) async {
    final hadManualAddress = values.address.trim().isNotEmpty;
    _values.value = values.copyWith(lat: lat, lng: lng);

    if (hadManualAddress) {
      return;
    }

    _isResolvingAddress.value = true;
    try {
      final address = await _repository.reverseGeocode(lat, lng);
      if (address != null) {
        _values.value = values.copyWith(address: address);
      }
    } finally {
      _isResolvingAddress.value = false;
    }
  }

  /// 저장에 성공하면 장소 id, 실패하면 `null`을 돌려줍니다.
  Future<int?> submit() async {
    if (_isSubmitting.value) {
      return null;
    }

    final invalid = values.validate();
    if (invalid != null) {
      // 서버에 보내지 않고 즉시 알립니다.
      _errorMessage.value = invalid;
      return null;
    }

    _isSubmitting.value = true;
    _errorMessage.value = null;

    try {
      final body = values.toRequestBody();
      final PlaceDetail saved;
      if (placeId case final int id) {
        saved = await _repository.updatePlace(id, body);
      } else {
        saved = await _repository.createPlace(body);
      }
      return saved.id;
    } on ApiException catch (error) {
      // 서버 메시지가 이미 한글입니다. 중복(409)·권한(403)·주소 실패(400) 모두
      // 사용자가 읽고 고칠 수 있는 문구로 옵니다.
      _errorMessage.value = error.message;
      return null;
    } on Object {
      _errorMessage.value = isEditing ? '장소를 수정하지 못했습니다.' : '장소를 등록하지 못했습니다.';
      return null;
    } finally {
      _isSubmitting.value = false;
    }
  }

  void clearError() => _errorMessage.value = null;
}
