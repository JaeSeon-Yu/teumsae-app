import 'package:get/get.dart';

import '../../features/account/settings_controller.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/places/my_places_controller.dart';
import '../../features/places/place_detail_controller.dart';
import '../../features/places/place_form_controller.dart';
import '../../features/places/place_map.dart';
import '../../features/places/places_controller.dart';
import '../../features/places/places_repository.dart';
import '../../features/saved/saved_controller.dart';
import '../../features/saved/saved_repository.dart';
import '../../features/shell/shell_controller.dart';
import '../network/api_client.dart';
import '../location/location_service.dart';
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

    // 위치 조회는 플랫폼 채널만 쓰고 상태가 없어서 앱 전체에 하나만 둡니다.
    Get.put<LocationService>(
      const GeolocatorLocationService(),
      permanent: true,
    );

    // 지도 위젯도 상태가 없습니다. 인터페이스로 등록해 두면
    // 위젯 테스트가 플랫폼 뷰 없는 대역으로 바꿔 끼울 수 있습니다.
    Get.put<PlaceMapBuilder>(
      const NaverPlaceMapBuilder(),
      permanent: true,
    );

    Get.put<SavedRepository>(
      SavedRepository(Get.find<ApiClient>()),
      permanent: true,
    );

    // 저장 상태는 검색 카드·상세·저장 탭이 함께 봐야 해서 앱 전체에 하나만 둡니다.
    Get.put<SavedController>(
      SavedController(
        repository: Get.find<SavedRepository>(),
        auth: Get.find<AuthController>(),
      ),
      permanent: true,
    );
  }
}

/// 하단 탭 셸(`/`) 진입 시 만들고, 셸을 벗어나면 정리합니다.
///
/// 검색 화면은 셸의 탭 안에 있어서 셸과 수명이 같습니다.
/// 그래서 검색 컨트롤러도 여기서 함께 등록합니다.
class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShellController>(ShellController.new);
    Get.lazyPut<PlacesController>(
      () => PlacesController(
        repository: Get.find<PlacesRepository>(),
        location: Get.find<LocationService>(),
      ),
    );
  }
}

/// 장소 상세(`/places/:id`) 진입 시 만듭니다.
///
/// 장소 id는 라우트 파라미터로 받습니다. 없거나 숫자가 아니면 0을 넘겨
/// 컨트롤러가 서버에서 404를 받고 "없는 장소" 화면을 보여 주게 합니다.
class PlaceDetailBinding extends Bindings {
  @override
  void dependencies() {
    final id = int.tryParse(Get.parameters['id'] ?? '') ?? 0;

    Get.lazyPut<PlaceDetailController>(
      () => PlaceDetailController(
        repository: Get.find<PlacesRepository>(),
        id: id,
      ),
    );
  }
}

/// 장소 등록(`/places/new`)·수정(`/places/:id/edit`) 진입 시 만듭니다.
///
/// 수정이면 라우트 파라미터의 id를 넘깁니다. 등록이면 `null`입니다.
class PlaceFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlaceFormController>(
      () => PlaceFormController(
        repository: Get.find<PlacesRepository>(),
        placeId: int.tryParse(Get.parameters['id'] ?? ''),
      ),
    );
  }
}

/// 내가 등록한 장소(`/account/places`) 진입 시 만듭니다.
class MyPlacesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyPlacesController>(
      () => MyPlacesController(Get.find<PlacesRepository>()),
    );
  }
}

/// 계정 설정(`/settings`) 진입 시 만듭니다.
class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(
      () => SettingsController(Get.find<AuthController>()),
    );
  }
}
