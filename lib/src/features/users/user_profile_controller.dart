import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import 'user_profile.dart';
import 'users_repository.dart';

/// 공개 프로필 화면 상태. [UserProfileBinding]이 라우트 진입 시 등록합니다.
///
/// 아이디는 라우트 파라미터(`/users/:username`)로 받습니다.
class UserProfileController extends GetxController {
  UserProfileController({
    required UsersRepository repository,
    required this.username,
  }) : _repository = repository;

  final UsersRepository _repository;
  final String username;

  final _profile = Rxn<UserProfile>();
  final _isLoading = true.obs;
  final _errorMessage = RxnString();

  UserProfile? get profile => _profile.value;
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
      _profile.value = await _repository.getProfile(username);
    } on ApiException catch (error) {
      _profile.value = null;
      _errorMessage.value =
          error.statusCode == 404 ? '없는 사용자입니다.' : error.message;
    } on Object {
      _profile.value = null;
      _errorMessage.value = '사용자 정보를 불러오지 못했습니다.';
    } finally {
      _isLoading.value = false;
    }
  }
}
