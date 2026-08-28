import 'dart:async';

import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_user.dart';
import 'saved_place.dart';
import 'saved_repository.dart';

/// 저장 상태의 단일 출처.
///
/// 검색 카드·상세 화면·저장 탭이 모두 이 컨트롤러를 봅니다. 화면마다 따로 들고 있으면
/// 상세에서 저장한 장소가 목록에서는 저장 안 된 것처럼 보이게 됩니다.
/// 그래서 [InitialBinding]에서 `permanent`로 등록합니다.
///
/// 로그인하지 않으면 목록은 항상 비어 있습니다. (서버가 401을 주는 엔드포인트)
class SavedController extends GetxController {
  SavedController({
    required SavedRepository repository,
    required AuthController auth,
  })  : _repository = repository,
        _auth = auth;

  final SavedRepository _repository;
  final AuthController _auth;

  final _places = <SavedPlace>[].obs;
  final _savedIds = <int>{}.obs;
  final _pendingIds = <int>{}.obs;
  final _isLoading = false.obs;
  final _errorMessage = RxnString();

  StreamSubscription<AuthUser?>? _authSubscription;

  List<SavedPlace> get places => _places;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;
  int get count => _places.length;

  bool isSaved(int placeId) => _savedIds.contains(placeId);

  /// 저장·취소 요청이 오가는 중인지. 버튼을 잠그는 데 씁니다.
  bool isPending(int placeId) => _pendingIds.contains(placeId);

  @override
  void onInit() {
    super.onInit();

    if (_auth.isSignedIn) {
      load();
    }

    // 앱 시작 직후의 자동 로그인도 이 스트림으로 들어옵니다.
    _authSubscription = _auth.userChanges.listen((user) {
      if (user == null) {
        _reset();
      } else {
        load();
      }
    });
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  Future<void> load() async {
    if (!_auth.isSignedIn) {
      _reset();
      return;
    }

    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      final places = await _repository.list();
      _places.assignAll(places);
      _savedIds
        ..clear()
        ..addAll(places.map((place) => place.id));
    } on ApiException catch (error) {
      _errorMessage.value = error.message;
    } on Object {
      _errorMessage.value = '저장한 장소를 불러오지 못했습니다.';
    } finally {
      _isLoading.value = false;
    }
  }

  /// 저장 상태를 뒤집습니다. 로그인 상태가 아니면 아무것도 하지 않고 `false`를 줍니다.
  ///
  /// 목록 정합성을 위해 성공 후 서버 목록을 다시 불러옵니다.
  /// (저장 시각·표시 정보를 서버가 채워 주기 때문에 로컬에서 만들 수 없습니다)
  Future<bool> toggle(int placeId) async {
    if (!_auth.isSignedIn || _pendingIds.contains(placeId)) {
      return false;
    }

    final wasSaved = isSaved(placeId);
    _pendingIds.add(placeId);
    _errorMessage.value = null;

    try {
      if (wasSaved) {
        await _repository.unsave(placeId);
        _savedIds.remove(placeId);
        _places.removeWhere((place) => place.id == placeId);
      } else {
        await _repository.save(placeId);
        _savedIds.add(placeId);
        await load();
      }
      return true;
    } on ApiException catch (error) {
      _errorMessage.value = error.message;
      return false;
    } on Object {
      _errorMessage.value = '저장 상태를 변경하지 못했습니다.';
      return false;
    } finally {
      _pendingIds.remove(placeId);
    }
  }

  void clearError() => _errorMessage.value = null;

  void _reset() {
    _places.clear();
    _savedIds.clear();
    _pendingIds.clear();
    _errorMessage.value = null;
  }
}
