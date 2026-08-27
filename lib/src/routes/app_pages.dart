import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/bindings/initial_binding.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_screen.dart';
import '../features/places/search_screen.dart';
import 'app_routes.dart';

/// 이미 로그인한 사용자가 로그인·회원가입 화면으로 가는 것을 되돌립니다.
///
/// 검색은 공개 화면이라(서버에서 `GET /api/places/**` 허용) 반대 방향 가드는 두지 않습니다.
class RedirectSignedInMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<AuthController>()) {
      return null;
    }
    return Get.find<AuthController>().isSignedIn
        ? const RouteSettings(name: AppRoutes.search)
        : null;
  }
}

abstract final class AppPages {
  static const initial = AppRoutes.search;

  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchScreen(),
      binding: PlacesBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const AuthScreen(mode: AuthMode.login),
      middlewares: [RedirectSignedInMiddleware()],
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const AuthScreen(mode: AuthMode.signup),
      middlewares: [RedirectSignedInMiddleware()],
    ),
  ];
}
