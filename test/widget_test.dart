import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:teumsae_app/src/core/network/api_client.dart';
import 'package:teumsae_app/src/core/network/auth_tokens.dart';
import 'package:teumsae_app/src/core/storage/token_store.dart';
import 'package:teumsae_app/src/core/theme/app_theme.dart';
import 'package:teumsae_app/src/features/auth/auth_controller.dart';
import 'package:teumsae_app/src/features/auth/auth_repository.dart';
import 'package:teumsae_app/src/features/auth/auth_user.dart';
import 'package:teumsae_app/src/features/places/place_detail.dart';
import 'package:teumsae_app/src/features/places/place_detail_controller.dart';
import 'package:teumsae_app/src/features/places/place_search_query.dart';
import 'package:teumsae_app/src/features/places/place_summary.dart';
import 'package:teumsae_app/src/features/places/places_controller.dart';
import 'package:teumsae_app/src/features/places/places_repository.dart';
import 'package:teumsae_app/src/features/places/search_filters_sheet.dart';
import 'package:teumsae_app/src/features/saved/save_place_button.dart';
import 'package:teumsae_app/src/features/saved/saved_controller.dart';
import 'package:teumsae_app/src/features/saved/saved_place.dart';
import 'package:teumsae_app/src/features/saved/saved_repository.dart';
import 'package:teumsae_app/src/features/shell/shell_controller.dart';
import 'package:teumsae_app/src/features/shell/shell_tab.dart';
import 'package:teumsae_app/src/routes/app_pages.dart';
import 'package:teumsae_app/src/routes/app_routes.dart';
import 'package:teumsae_app/src/widgets/score_badge.dart';

/// 검색은 항상 서버를 호출하므로 목록만 돌려주는 대역으로 바꿉니다.
class _StubPlacesRepository extends PlacesRepository {
  _StubPlacesRepository(this.stubbed)
      : super(ApiClient(tokenStore: InMemoryTokenStore()));

  final List<PlaceSummary> stubbed;

  @override
  Future<List<PlaceSummary>> search(PlaceSearchQuery query) async => stubbed;

  @override
  Future<PlaceDetail> getPlace(int id) async => PlaceDetail.fromJson({
        'id': id,
        'name': '성북구립도서관',
        'typeLabel': '도서관',
        'address': '서울 성북구 화랑로',
        'lat': 37.5921,
        'lng': 127.0161,
        'priceLabel': '무료',
        'indoor': true,
        'stayMinutesMin': 30,
        'stayMinutesMax': 180,
        'openStatusLabel': '영업중',
        'scores': {'seating': 5, 'quiet': 4},
        'weatherScores': {'rain': 5},
        'openingHoursText': '평일 09:00-18:00',
        'warnings': ['음식물 반입 금지'],
        'tags': ['조용함'],
      });
}

/// 저장 목록도 서버를 호출하므로 메모리 목록으로 바꿉니다.
class _StubSavedRepository extends SavedRepository {
  _StubSavedRepository({List<int>? initialIds})
      : _ids = {...?initialIds},
        super(ApiClient(tokenStore: InMemoryTokenStore()));

  final Set<int> _ids;

  @override
  Future<List<SavedPlace>> list() async => _ids
      .map((id) => SavedPlace.fromJson({
            'id': id,
            'name': '성북구립도서관',
            'typeLabel': '도서관',
            'address': '서울 성북구 화랑로',
            'priceLabel': '무료',
            'indoor': true,
            'stayMinutesMin': 30,
            'stayMinutesMax': 180,
            'tags': ['조용함'],
            'savedAt': '2026-08-28T10:00:00',
          }))
      .toList(growable: false);

  @override
  Future<void> save(int placeId) async => _ids.add(placeId);

  @override
  Future<void> unsave(int placeId) async => _ids.remove(placeId);
}

/// 자동 로그인 결과만 정해 주는 대역. 서버를 호출하지 않습니다.
class _StubAuthRepository extends AuthRepository {
  _StubAuthRepository({this.restored})
      : super(
          apiClient: ApiClient(tokenStore: InMemoryTokenStore()),
          tokenStore: InMemoryTokenStore(),
        );

  final AuthSession? restored;

  @override
  Future<AuthSession?> restoreSession() async => restored;

  @override
  Future<void> logout() async {}

  @override
  Future<AuthUser> updateNickname(String nickname) async => AuthUser(
        id: 1,
        username: 'teumsae_user',
        nickname: nickname.trim(),
        role: 'USER',
        provider: 'LOCAL',
      );

  @override
  Future<AuthSession> changePassword({
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async =>
      _session();

  @override
  Future<void> deleteAccount(String password) async {}
}

AuthSession _session() => AuthSession(
      user: const AuthUser(
        id: 1,
        username: 'teumsae_user',
        nickname: '틈새유저',
        role: 'USER',
        provider: 'LOCAL',
      ),
      tokens: AuthTokens(
        tokenType: 'Bearer',
        accessToken: 'access',
        accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
        refreshToken: 'refresh',
      ),
    );

/// 실제 앱과 같은 라우트·바인딩으로 띄우되, 의존성만 테스트용으로 갈아끼웁니다.
///
/// 보안 저장소는 플랫폼 채널을 쓰므로 [InMemoryTokenStore]로 바꿉니다.
/// [signedIn]이 `false`면 자동 로그인 시도가 네트워크를 타지 않고 바로 끝납니다.
Future<void> _pumpApp(
  WidgetTester tester, {
  List<PlaceSummary> places = const [],
  String initialRoute = AppRoutes.home,
  bool signedIn = false,
  List<int> savedIds = const [],
}) async {
  Get.testMode = true;

  final tokenStore = InMemoryTokenStore();
  final apiClient = ApiClient(tokenStore: tokenStore);

  Get.put<TokenStore>(tokenStore, permanent: true);
  Get.put<ApiClient>(apiClient, permanent: true);
  Get.put<AuthRepository>(
    _StubAuthRepository(restored: signedIn ? _session() : null),
    permanent: true,
  );
  Get.put<AuthController>(AuthController(Get.find()), permanent: true);
  // ShellController와 PlacesController는 ShellBinding이 만들어 줍니다.
  Get.put<PlacesRepository>(_StubPlacesRepository(places), permanent: true);
  Get.put<SavedRepository>(
    _StubSavedRepository(initialIds: savedIds),
    permanent: true,
  );
  Get.put<SavedController>(
    SavedController(repository: Get.find(), auth: Get.find()),
    permanent: true,
  );

  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.light(),
      initialRoute: initialRoute,
      getPages: AppPages.pages,
    ),
  );
  await tester.pumpAndSettle();
}

/// 하단 탭의 라벨. 같은 문구가 화면 앱바에도 있어서 탭 영역으로 한정합니다.
Finder _tab(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

/// 저장 버튼의 아이콘. 하단 탭에도 같은 북마크 아이콘이 있어서 버튼 안으로 한정합니다.
Finder _saveIcon({required bool saved}) => find.descendant(
      of: find.byType(SavePlaceButton),
      matching: find.byIcon(saved ? Icons.bookmark : Icons.bookmark_border),
    );

/// 조건 시트 안을 스크롤합니다. 화면 밖 항목은 아직 만들어지지 않습니다.
Future<void> _scrollSheetTo(WidgetTester tester, Finder target) {
  return tester.scrollUntilVisible(
    target,
    200,
    scrollable: find
        .descendant(
          of: find.byType(SearchFiltersSheet),
          matching: find.byType(Scrollable),
        )
        .first,
  );
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
    scoreLabel: '지금 딱 좋음',
    reasons: ['조용해요', '앉을 자리 많아요'],
    tags: ['wifi'],
    openStatusLabel: '영업 중',
  );

  group('셸', () {
    testWidgets('검색 탭으로 시작하고 결과를 보여준다', (tester) async {
      await _pumpApp(tester, places: const [samplePlace]);

      expect(Get.find<ShellController>().tab, ShellTab.search);
      expect(find.text('틈새'), findsOneWidget);
      expect(find.text('성북구립도서관'), findsOneWidget);
      expect(find.textContaining('420m'), findsOneWidget);
    });

    testWidgets('하단 탭으로 내 정보로 옮긴다', (tester) async {
      await _pumpApp(tester, places: const [samplePlace]);

      await tester.tap(_tab('내 정보'));
      await tester.pumpAndSettle();

      expect(Get.find<ShellController>().tab, ShellTab.account);

      await tester.tap(_tab('저장'));
      await tester.pumpAndSettle();

      expect(Get.find<ShellController>().tab, ShellTab.saved);

      await tester.tap(_tab('검색'));
      await tester.pumpAndSettle();

      expect(Get.find<ShellController>().tab, ShellTab.search);
    });
  });

  group('저장 탭', () {
    Future<void> openSavedTab(WidgetTester tester) async {
      await tester.tap(_tab('저장'));
      await tester.pumpAndSettle();
    }

    testWidgets('로그아웃 상태에서는 로그인을 안내한다', (tester) async {
      await _pumpApp(tester);
      await openSavedTab(tester);

      expect(find.text('로그인하면 저장한 틈새를 볼 수 있습니다.'), findsOneWidget);
    });

    testWidgets('저장한 장소가 없으면 안내 문구를 보여준다', (tester) async {
      await _pumpApp(tester, signedIn: true);
      await openSavedTab(tester);

      expect(find.text('저장한 장소가 없습니다.'), findsOneWidget);
    });

    testWidgets('로그인 상태에서는 저장 목록과 개수를 보여준다', (tester) async {
      await _pumpApp(tester, signedIn: true, savedIds: const [1, 2]);
      await openSavedTab(tester);

      expect(find.text('총 2개'), findsOneWidget);
      expect(find.text('성북구립도서관'), findsNWidgets(2));
      expect(find.text('2026. 8. 28. 저장'), findsNWidgets(2));
    });

    testWidgets('저장을 취소하면 목록에서 사라진다', (tester) async {
      await _pumpApp(tester, signedIn: true, savedIds: const [1]);
      await openSavedTab(tester);

      await tester.tap(_saveIcon(saved: true));
      await tester.pumpAndSettle();

      expect(find.text('저장한 장소가 없습니다.'), findsOneWidget);
    });
  });

  group('검색 탭', () {
    testWidgets('결과가 없으면 안내 문구를 보여준다', (tester) async {
      await _pumpApp(tester);

      expect(find.text('조건에 맞는 틈새가 없습니다.'), findsOneWidget);
    });

    testWidgets('테마를 바꾸면 검색 조건이 갱신된다', (tester) async {
      await _pumpApp(tester, places: const [samplePlace]);

      await tester.tap(find.widgetWithText(ChoiceChip, '화장실'));
      await tester.pumpAndSettle();

      expect(Get.find<PlacesController>().query.theme, SearchTheme.toilet);
    });

    testWidgets('정렬과 영업중 토글이 조건에 반영된다', (tester) async {
      await _pumpApp(tester, places: const [samplePlace]);
      final controller = Get.find<PlacesController>();

      await tester.tap(find.widgetWithText(ChoiceChip, '가까운순'));
      await tester.pumpAndSettle();
      expect(controller.query.sort, SearchSort.distance);

      await tester.tap(find.widgetWithText(FilterChip, '지금 운영중'));
      await tester.pumpAndSettle();
      expect(controller.query.openOnly, isTrue);
    });

    testWidgets('조건 시트에서 고른 값은 적용을 눌러야 반영된다', (tester) async {
      await _pumpApp(tester, places: const [samplePlace]);
      final controller = Get.find<PlacesController>();

      await tester.tap(find.widgetWithText(OutlinedButton, '조건'));
      await tester.pumpAndSettle();

      expect(find.text('검색 조건'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, '무료'));
      await tester.pumpAndSettle();
      await _scrollSheetTo(tester, find.widgetWithText(FilterChip, '와이파이'));
      await tester.tap(find.widgetWithText(FilterChip, '와이파이'));
      await tester.pumpAndSettle();

      // 아직 적용하지 않았으므로 조건은 그대로입니다.
      expect(controller.query.budget, SearchBudget.any);

      await tester.tap(find.widgetWithText(FilledButton, '조건 적용'));
      await tester.pumpAndSettle();

      expect(controller.query.budget, SearchBudget.free);
      expect(controller.query.needs, {SearchNeed.wifi});
      // 바뀐 항목 수가 조건 버튼에 보입니다.
      expect(find.widgetWithText(OutlinedButton, '조건 2'), findsOneWidget);
    });

    testWidgets('조건 시트를 닫으면 아무것도 바뀌지 않는다', (tester) async {
      await _pumpApp(tester, places: const [samplePlace]);
      final controller = Get.find<PlacesController>();

      await tester.tap(find.widgetWithText(OutlinedButton, '조건'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, '실내'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('검색 조건 닫기'));
      await tester.pumpAndSettle();

      expect(controller.query.space, SearchSpace.any);
    });

    testWidgets('조건 초기화는 시트 안의 항목만 되돌린다', (tester) async {
      await _pumpApp(tester, places: const [samplePlace]);
      final controller = Get.find<PlacesController>();
      await controller.changeSort(SearchSort.distance);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, '조건'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '30분'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '초기화'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '조건 적용'));
      await tester.pumpAndSettle();

      expect(controller.query.stayMinutes, 0);
      expect(controller.query.sort, SearchSort.distance);
    });

    testWidgets('점수 배지에 서버 등급 문구를 그대로 쓴다', (tester) async {
      await _pumpApp(tester, places: const [samplePlace]);

      expect(find.widgetWithText(ScoreBadge, '87'), findsOneWidget);
      expect(find.widgetWithText(ScoreBadge, '지금 딱 좋음'), findsOneWidget);
    });

    testWidgets('카드를 누르면 장소 상세로 이동한다', (tester) async {
      await _pumpApp(tester, places: const [samplePlace]);

      await tester.tap(find.text('성북구립도서관'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.placeDetail(samplePlace.id));
      expect(Get.find<PlaceDetailController>().id, samplePlace.id);
    });

    testWidgets('로그아웃 상태에서 저장을 누르면 로그인 화면으로 보낸다', (tester) async {
      // 서버에 401을 만들지 않고 미리 막습니다.
      await _pumpApp(tester, places: const [samplePlace]);

      await tester.tap(_saveIcon(saved: false));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.login);
    });

    testWidgets('로그인 상태에서 저장하면 저장 상태가 공유된다', (tester) async {
      await _pumpApp(tester, places: const [samplePlace], signedIn: true);

      await tester.tap(_saveIcon(saved: false));
      await tester.pumpAndSettle();

      expect(Get.find<SavedController>().isSaved(samplePlace.id), isTrue);
      // 같은 컨트롤러를 보므로 저장 탭에도 바로 반영됩니다.
      await tester.tap(_tab('저장'));
      await tester.pumpAndSettle();
      expect(find.text('총 1개'), findsOneWidget);
    });
  });

  group('장소 상세', () {
    Future<void> openDetail(WidgetTester tester) async {
      await _pumpApp(tester, places: const [samplePlace]);
      await tester.tap(find.text('성북구립도서관'));
      await tester.pumpAndSettle();
    }

    testWidgets('서버가 준 정보를 구역별로 보여준다', (tester) async {
      await openDetail(tester);

      // 헤더
      expect(find.text('영업중'), findsOneWidget);
      expect(find.text('서울 성북구 화랑로'), findsOneWidget);
      expect(find.text('무료'), findsOneWidget);
      expect(find.text('실내'), findsOneWidget);
      expect(find.text('30분-3시간'), findsOneWidget);
      // 경고
      expect(find.text('가기 전 체크'), findsOneWidget);
      expect(find.text('음식물 반입 금지'), findsOneWidget);
      // 편의 점수
      expect(find.text('편의 점수'), findsOneWidget);
      expect(find.text('5/5'), findsWidgets);

      // 아래 구역은 화면 밖에 있어 ListView가 아직 만들지 않았습니다.
      await tester.scrollUntilVisible(find.text('상황 적합도'), 300);
      expect(find.text('상황 적합도'), findsOneWidget);

      // 운영 정보
      await tester.scrollUntilVisible(find.text('09:00-18:00'), 300);
      expect(find.text('평일'), findsOneWidget);

      // 태그·위치
      await tester.scrollUntilVisible(find.text('#조용함'), 300);
      await tester.scrollUntilVisible(find.text('37.592100, 127.016100'), 300);
      expect(find.text('37.592100, 127.016100'), findsOneWidget);
    });

    testWidgets('상세에는 점수 배지를 두지 않는다', (tester) async {
      // 서버 `/api/places/{id}`는 검색 조건이 없어 restScore를 계산하지 않습니다.
      await openDetail(tester);

      expect(find.byType(ScoreBadge), findsNothing);
    });

    testWidgets('로그인 상태에서 상세의 저장 버튼이 동작한다', (tester) async {
      await _pumpApp(tester, places: const [samplePlace], signedIn: true);
      await tester.tap(find.text('성북구립도서관'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, '저장'));
      await tester.pumpAndSettle();

      expect(Get.find<SavedController>().isSaved(samplePlace.id), isTrue);
      expect(find.widgetWithText(FilledButton, '저장됨'), findsOneWidget);
    });
  });

  group('내 정보 탭', () {
    // IndexedStack의 선택되지 않은 탭은 offstage라 기본 finder가 건너뜁니다.
    // 그래서 내용을 확인하기 전에 실제 사용처럼 탭을 먼저 엽니다.
    Future<void> openAccountTab(WidgetTester tester) async {
      await tester.tap(_tab('내 정보'));
      await tester.pumpAndSettle();
    }

    testWidgets('로그아웃 상태에서는 로그인·회원가입을 안내한다', (tester) async {
      await _pumpApp(tester);
      await openAccountTab(tester);

      expect(find.text('로그인하면 틈새를 저장할 수 있습니다.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '로그인'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '회원가입'), findsOneWidget);
    });

    testWidgets('로그인 상태에서는 프로필과 로그아웃을 보여준다', (tester) async {
      await _pumpApp(tester, signedIn: true);
      await openAccountTab(tester);

      expect(find.text('틈새유저'), findsOneWidget);
      expect(find.text('@teumsae_user'), findsOneWidget);
      expect(find.text('일반 회원'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '로그아웃'), findsOneWidget);
      // 로그인 안내는 사라집니다.
      expect(find.widgetWithText(FilledButton, '로그인'), findsNothing);
    });

    testWidgets('로그아웃을 누르면 다시 로그인 안내로 돌아간다', (tester) async {
      await _pumpApp(tester, signedIn: true);
      await openAccountTab(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, '로그아웃'));
      await tester.pumpAndSettle();

      expect(find.text('@teumsae_user'), findsNothing);
      expect(find.widgetWithText(FilledButton, '로그인'), findsOneWidget);
    });

    testWidgets('설정 화면으로 이동한다', (tester) async {
      await _pumpApp(tester, signedIn: true);
      await openAccountTab(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, '계정 및 보안 설정'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.settings);
      // 구역 제목과 제출 버튼에 같은 문구가 쓰입니다.
      expect(find.text('닉네임 변경'), findsWidgets);
      expect(find.text('비밀번호 변경'), findsWidgets);

      // 탈퇴 구역은 화면 밖에 있어 스크롤해야 만들어집니다.
      // 스크롤 대상은 하나만 잡혀야 하므로 입력 칸을 씁니다.
      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, '비밀번호 재확인'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('회원 탈퇴'), findsWidgets);
    });
  });

  group('설정 화면', () {
    testWidgets('로그인하지 않으면 로그인 화면으로 보낸다', (tester) async {
      await _pumpApp(tester, initialRoute: AppRoutes.settings);

      expect(Get.currentRoute, AppRoutes.login);
    });

    testWidgets('닉네임을 저장하면 내 정보에도 반영된다', (tester) async {
      await _pumpApp(tester, initialRoute: AppRoutes.settings, signedIn: true);

      await tester.enterText(find.byType(TextFormField).first, '새 닉네임');
      await tester.tap(find.widgetWithText(FilledButton, '닉네임 저장'));
      await tester.pumpAndSettle();

      expect(find.text('닉네임을 저장했습니다.'), findsOneWidget);
      expect(Get.find<AuthController>().user?.nickname, '새 닉네임');
    });

    testWidgets('닉네임이 비면 서버를 부르지 않고 막는다', (tester) async {
      await _pumpApp(tester, initialRoute: AppRoutes.settings, signedIn: true);

      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.tap(find.widgetWithText(FilledButton, '닉네임 저장'));
      await tester.pump();

      expect(find.text('닉네임을 입력해 주세요.'), findsOneWidget);
    });

    testWidgets('새 비밀번호 확인이 어긋나면 서버를 부르지 않는다', (tester) async {
      await _pumpApp(tester, initialRoute: AppRoutes.settings, signedIn: true);

      await tester.enterText(
        find.widgetWithText(TextFormField, '현재 비밀번호'),
        'old-password',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '새 비밀번호'),
        'new-password',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '새 비밀번호 확인'),
        'new-password-typo',
      );
      await tester.tap(find.widgetWithText(FilledButton, '비밀번호 변경'));
      await tester.pumpAndSettle();

      expect(find.text('새 비밀번호가 서로 일치하지 않습니다.'), findsOneWidget);
    });

    testWidgets('회원 탈퇴는 한 번 더 확인한다', (tester) async {
      await _pumpApp(tester, initialRoute: AppRoutes.settings, signedIn: true);

      // 입력 칸마다 내부 Scrollable이 있어 목록 쪽을 명시해야 합니다.
      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, '비밀번호 재확인'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '비밀번호 재확인'),
        'password',
      );
      await tester.tap(find.widgetWithText(FilledButton, '회원 탈퇴'));
      await tester.pumpAndSettle();

      expect(find.text('탈퇴 후에는 이 계정으로 다시 로그인할 수 없습니다. 계속하시겠습니까?'),
          findsOneWidget);

      // 취소하면 계정은 그대로입니다.
      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pumpAndSettle();

      expect(Get.find<AuthController>().isSignedIn, isTrue);
    });
  });

  group('인증 화면', () {
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
  });
}
