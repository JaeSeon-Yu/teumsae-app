import 'package:get/get.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/places/places_controller.dart';
import '../../features/places/places_repository.dart';
import '../network/api_client.dart';
import '../storage/token_store.dart';

/// 앱 시작 시 한 번 등록하는 의존성.
///
/// [AuthController]는 로그인 상태를 앱 전체가 공유하므로 `permanent`로 둡니다.
/// 라우트가 바뀌어도 살아 있어야 합니다.
class InitialBinding extends Bindings {
  @override
  void dependencies() {    Get.put<TokenStore>(SecureTokenStore(), permanent: true);

    Get.put<ApiClient>(
      ApiClient(
        tokenStore: Get.find<TokenStore>(),
        // AuthController를 직접 참조하면 의존성이 순환합니다.
        // (ApiClient → AuthController → AuthRepository → ApiClient)
        // 그래서 호출 시점에 찾아 씁니다. 아직 없으면 그냥 무시합니다.
        onSessionExpired: () {
          if (Get.isRegistered<AuthController>()) {
            Get.find<AuthController>().handleSessionExpired();
          }
        },
      ),
      permanent: true,
    );

    Get.put<AuthRepository>(
      AuthRepository(
        apiClient: Get.find<ApiClient>(),
        tokenStore: Get.find<TokenStore>(),
      ),
      permanent: true,
    );

    Get.put<AuthController>(
      AuthController(Get.find<AuthRepository>()),
      permanent: true,
    );

    Get.put<PlacesRepository>(
      PlacesRepository(Get.find<ApiClient>()),
      permanent: true,
    );
  }
}

/// 검색 화면 진입 시에만 만들고, 화면을 벗어나면 정리합니다.
class PlacesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlacesController>(
      () => PlacesController(Get.find<PlacesRepository>()),
    );
  }
}
