import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:teumsae_app/src/core/network/api_client.dart';
import 'package:teumsae_app/src/core/storage/token_store.dart';
import 'package:teumsae_app/src/core/theme/app_theme.dart';
import 'package:teumsae_app/src/features/auth/auth_controller.dart';
import 'package:teumsae_app/src/features/auth/auth_repository.dart';
import 'package:teumsae_app/src/features/places/place_summary.dart';
import 'package:teumsae_app/src/features/places/places_controller.dart';
import 'package:teumsae_app/src/features/places/places_repository.dart';
import 'package:teumsae_app/src/routes/app_pages.dart';
import 'package:teumsae_app/src/routes/app_routes.dart';

/// 검색은 항상 서버를 호출하므로 목록만 돌려주는 대역으로 바꿉니다.
class _StubPlacesRepository extends PlacesRepository {
  _StubPlacesRepository(this.stubbed)
      : super(ApiClient(tokenStore: InMemoryTokenStore()));

  final List<PlaceSummary> stubbed;

  @override
  Future<List<PlaceSummary>> search(PlaceSearchQuery query) async => stubbed;
}

/// 실제 앱과 같은 라우트·바인딩으로 띄우되, 의존성만 테스트용으로 갈아끼웁니다.
///
/// 보안 저장소는 플랫폼 채널을 쓰므로 [InMemoryTokenStore]로 바꿉니다.
/// 저장된 토큰이 없으면 자동 로그인 시도가 네트워크를 타지 않고 바로 끝납니다.
Future<void> _pumpApp(
  WidgetTester tester, {
  List<PlaceSummary> places = const [],
  String initialRoute = AppRoutes.search,
}) async {
  Get.testMode = true;

  final tokenStore = InMemoryTokenStore();
  final apiClient = ApiClient(tokenStore: tokenStore);

  Get.put<TokenStore>(tokenStore, permanent: true);
  Get.put<ApiClient>(apiClient, permanent: true);
  Get.put<AuthRepository>(
    AuthRepository(apiClient: apiClient, tokenStore: tokenStore),
    permanent: true,
  );
  Get.put<AuthController>(AuthController(Get.find()), permanent: true);
  // PlacesController는 PlacesBinding이 이 리포지토리로 만들어 줍니다.
  Get.put<PlacesRepository>(_StubPlacesRepository(places), permanent: true);

  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.light(),
      initialRoute: initialRoute,
      getPages: AppPages.pages,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(Get.reset);

  const samplePlace = PlaceSummary(
    id: 1,
    name: '성북구립도서관',
    typeLabel: '도서관',
    address: '서울 성북구 화랑로',
    distanceMeters: 420,
    priceLabel: '무료',
    restScore: 87,
    scoreLabel: '아주 좋아요',
    reasons: ['조용해요', '앉을 자리 많아요'],
    tags: ['wifi'],
    openStatusLabel: '영업 중',
  );

  testWidgets('검색 화면이 결과와 로그인 버튼을 보여준다', (tester) async {
    await _pumpApp(tester, places: const [samplePlace]);

    expect(find.text('틈새'), findsOneWidget);
    expect(find.text('성북구립도서관'), findsOneWidget);
    expect(find.textContaining('420m'), findsOneWidget);
    // 로그인하지 않은 상태에서는 로그인 버튼이 보입니다.
    expect(find.widgetWithText(TextButton, '로그인'), findsOneWidget);
  });

  testWidgets('결과가 없으면 안내 문구를 보여준다', (tester) async {
    await _pumpApp(tester);

    expect(find.text('조건에 맞는 틈새가 없습니다.'), findsOneWidget);
  });

  testWidgets('테마를 바꾸면 검색 조건이 갱신된다', (tester) async {
    await _pumpApp(tester, places: const [samplePlace]);

    await tester.tap(find.widgetWithText(ChoiceChip, '화장실'));
    await tester.pumpAndSettle();

    expect(Get.find<PlacesController>().query.theme, 'TOILET');
  });

  testWidgets('로그인 화면은 빈 입력을 서버 호출 없이 막는다', (tester) async {
    await _pumpApp(tester, initialRoute: AppRoutes.login);

    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pump();

    expect(find.text('아이디를 입력해 주세요.'), findsOneWidget);
    expect(find.text('비밀번호를 입력해 주세요.'), findsOneWidget);
  });

  testWidgets('회원가입 화면은 서버 규칙을 한글로 안내한다', (tester) async {
    await _pumpApp(tester, initialRoute: AppRoutes.signup);

    expect(find.text('영문 소문자, 숫자, 밑줄(_)로 4~20자'), findsOneWidget);
    expect(find.text('8자 이상 72자 이하'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Teumsae');
    await tester.tap(find.widgetWithText(FilledButton, '가입하고 시작하기'));
    await tester.pump();

    expect(
      find.text('아이디는 영문 소문자, 숫자, 밑줄(_)만 사용할 수 있습니다.'),
      findsOneWidget,
    );
  });
}
