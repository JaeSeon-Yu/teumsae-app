import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:teumsae_app/src/core/location/location_service.dart';
import 'package:teumsae_app/src/core/network/api_client.dart';
import 'package:teumsae_app/src/core/network/auth_tokens.dart';
import 'package:teumsae_app/src/core/storage/token_store.dart';
import 'package:teumsae_app/src/core/theme/app_theme.dart';
import 'package:teumsae_app/src/features/auth/auth_controller.dart';
import 'package:teumsae_app/src/features/auth/auth_repository.dart';
import 'package:teumsae_app/src/features/auth/auth_user.dart';
import 'package:teumsae_app/src/features/places/place_detail.dart';
import 'package:teumsae_app/src/features/places/my_places_controller.dart';
import 'package:teumsae_app/src/features/places/place_detail_controller.dart';
import 'package:teumsae_app/src/features/places/place_form.dart';
import 'package:teumsae_app/src/features/places/place_form_controller.dart';
import 'package:teumsae_app/src/features/places/place_map.dart';
import 'package:teumsae_app/src/features/places/place_review.dart';
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
import 'package:teumsae_app/src/features/users/block_controller.dart';
import 'package:teumsae_app/src/features/users/user_profile.dart';
import 'package:teumsae_app/src/features/users/users_repository.dart';
import 'package:teumsae_app/src/features/shell/shell_tab.dart';
import 'package:teumsae_app/src/routes/app_pages.dart';
import 'package:teumsae_app/src/routes/app_routes.dart';
import 'package:teumsae_app/src/widgets/score_badge.dart';

/// 검색은 항상 서버를 호출하므로 목록만 돌려주는 대역으로 바꿉니다.
class _StubPlacesRepository extends PlacesRepository {
  _StubPlacesRepository(this.stubbed, {this.reviews = const []})
      : super(ApiClient(tokenStore: InMemoryTokenStore()));

  final List<PlaceSummary> stubbed;

  /// 마지막으로 요청된 조건. 위치 변경이 실제 검색에 반영됐는지 확인합니다.
  PlaceSearchQuery? lastQuery;

  @override
  Future<List<PlaceSummary>> search(PlaceSearchQuery query) async {
    lastQuery = query;
    return stubbed;
  }

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
        'reviewCount': reviews.length,
        'reviews': reviews,
        'averageRating': reviews.isEmpty
            ? null
            : reviews
                    .map((review) => review['rating'] as int)
                    .reduce((a, b) => a + b) /
                reviews.length,
      });

  /// 상세 응답에 실어 보낼 후기. 작성·삭제가 이 목록을 바꿉니다.
  List<Map<String, dynamic>> reviews;

  ({int rating, String comment})? lastCreatedReview;

  @override
  Future<PlaceReview> createReview({
    required int placeId,
    required int rating,
    required String comment,
  }) async {
    lastCreatedReview = (rating: rating, comment: comment);
    final created = {
      'id': 100,
      'userId': 1,
      'username': 'tester',
      'rating': rating,
      'comment': comment,
      'createdAt': '2026-08-28T23:04:11.123',
    };
    // 서버는 최신순으로 돌려줍니다.
    reviews = [created, ...reviews];
    return PlaceReview.fromJson(created);
  }

  @override
  Future<void> deleteReview({
    required int placeId,
    required int reviewId,
  }) async {
    reviews = reviews
        .where((review) => review['id'] != reviewId)
        .toList(growable: false);
  }

  Map<String, dynamic>? lastCreatedPlace;
  Map<String, dynamic>? lastUpdatedPlace;
  final deletedPlaceIds = <int>[];

  @override
  Future<List<PlaceTagOption>> tags() async => const [
        PlaceTagOption(name: 'INDOOR', label: '실내'),
        PlaceTagOption(name: 'WIFI', label: '와이파이'),
      ];

  @override
  Future<PlaceDetail> createPlace(Map<String, dynamic> body) async {
    lastCreatedPlace = body;
    return getPlace(99);
  }

  @override
  Future<PlaceDetail> updatePlace(int id, Map<String, dynamic> body) async {
    lastUpdatedPlace = body;
    return getPlace(id);
  }

  @override
  Future<void> deletePlace(int id) async => deletedPlaceIds.add(id);

  @override
  Future<List<PlaceDetail>> myPlaces() async =>
      [await getPlace(1), await getPlace(2)];

  @override
  Future<String?> reverseGeocode(double lat, double lng) async =>
      '서울 성북구 화랑로 123';
}

/// 차단·신고도 서버를 호출하므로 메모리로 바꿉니다.
class _StubUsersRepository extends UsersRepository {
  _StubUsersRepository({Set<int>? blockedIds, this.profile})
      : _blocked = {...?blockedIds},
        super(ApiClient(tokenStore: InMemoryTokenStore()));

  final Set<int> _blocked;

  /// 공개 프로필 응답. 없으면 기본값을 만들어 줍니다.
  final Map<String, dynamic>? profile;

  ({String target, int id, String reason})? lastReport;

  @override
  Future<Set<int>> blockedUserIds() async => {..._blocked};

  @override
  Future<void> block(int userId) async => _blocked.add(userId);

  @override
  Future<void> unblock(int userId) async => _blocked.remove(userId);

  @override
  Future<void> report({
    required ReportTarget target,
    required int targetId,
    required String reason,
    String? details,
  }) async {
    lastReport = (target: target.value, id: targetId, reason: reason);
  }

  @override
  Future<UserProfile> getProfile(String username) async {
    return UserProfile.fromJson(
      profile ??
          {
            'id': 99,
            'username': username,
            'createdAt': '2026-01-02T10:00:00.000',
            'registeredPlacesCount': 0,
            'reviewsCount': 0,
            'registeredPlaces': <Map<String, dynamic>>[],
            'reviews': <Map<String, dynamic>>[],
          },
    );
  }
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

/// 지도는 플랫폼 뷰라 위젯 테스트에서 그릴 수 없습니다.
/// 화면 배선(마커 탭 → 상세 이동, 지역 재검색)만 확인할 수 있는 대역을 씁니다.
class _FakePlaceMapBuilder implements PlaceMapBuilder {
  @override
  Widget results({
    required List<PlaceSummary> places,
    required double centerLat,
    required double centerLng,
    required ValueChanged<int> onPlaceTap,
    required void Function(double lat, double lng) onSearchArea,
  }) {
    return Column(
      children: [
        Text('지도 중심 $centerLat, $centerLng'),
        for (final place in places)
          TextButton(
            onPressed: () => onPlaceTap(place.id),
            child: Text('마커 ${place.name}'),
          ),
        TextButton(
          onPressed: () => onSearchArea(37.55, 126.99),
          child: const Text('이 지역 재검색'),
        ),
      ],
    );
  }

  @override
  Widget single({
    required double lat,
    required double lng,
    required String name,
  }) {
    return Text('지도 $name');
  }

  @override
  Widget picker({
    required double lat,
    required double lng,
    required void Function(double lat, double lng) onPicked,
  }) {
    return Column(
      children: [
        Text('핀 $lat, $lng'),
        TextButton(
          onPressed: () => onPicked(37.55, 126.99),
          child: const Text('지도에서 위치 고르기'),
        ),
      ],
    );
  }
}

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
  LocationService? location,
  List<Map<String, dynamic>> reviews = const [],
  Set<int> blockedIds = const {},
  Map<String, dynamic>? profile,
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
  Get.put<PlacesRepository>(
    _StubPlacesRepository(places, reviews: reviews),
    permanent: true,
  );
  // 실제 구현은 플랫폼 채널을 타므로 테스트에서는 고정 좌표를 씁니다.
  Get.put<LocationService>(
    location ?? const FixedLocationService(UserLocation(lat: 37.5, lng: 127.1)),
    permanent: true,
  );
  Get.put<PlaceMapBuilder>(_FakePlaceMapBuilder(), permanent: true);
  Get.put<SavedRepository>(
    _StubSavedRepository(initialIds: savedIds),
    permanent: true,
  );
  Get.put<SavedController>(
    SavedController(repository: Get.find(), auth: Get.find()),
    permanent: true,
  );
  Get.put<UsersRepository>(
    _StubUsersRepository(blockedIds: blockedIds, profile: profile),
    permanent: true,
  );
  Get.put<BlockController>(
    BlockController(repository: Get.find(), auth: Get.find()),
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

/// 화면 본문(`ListView`)을 스크롤합니다.
///
/// 입력칸(`TextField`)도 내부에 Scrollable을 만들기 때문에 기본
/// `scrollUntilVisible`은 어느 것을 굴릴지 정하지 못합니다. 그리고 화면 밖
/// 항목은 아직 만들어지지 않아 `ensureVisible`로는 찾을 수 없습니다.
Future<void> _scrollListTo(
  WidgetTester tester,
  Finder target, {
  /// 위쪽에 있는 항목을 찾을 때는 음수를 넘깁니다.
  double delta = 300,
}) {
  return tester.scrollUntilVisible(
    target,
    delta,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
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
    lat: 37.5921,
    lng: 127.0161,
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

    testWidgets('내 위치를 누르면 현재 좌표로 검색하고 다시 누르면 되돌린다', (tester) async {
      await _pumpApp(tester, places: const [samplePlace]);
      final repository = Get.find<PlacesRepository>() as _StubPlacesRepository;

      await tester.tap(find.widgetWithText(FilterChip, '내 위치'));
      await tester.pumpAndSettle();

      expect(Get.find<PlacesController>().usingCurrentLocation, isTrue);
      expect(repository.lastQuery?.lat, 37.5);

      await tester.tap(find.widgetWithText(FilterChip, '내 위치'));
      await tester.pumpAndSettle();

      expect(Get.find<PlacesController>().usingCurrentLocation, isFalse);
      expect(repository.lastQuery?.lat, 37.592);
    });

    testWidgets('위치 권한을 거부하면 안내만 띄우고 결과를 지우지 않는다', (tester) async {
      await _pumpApp(
        tester,
        places: const [samplePlace],
        location: const FailingLocationService(
          LocationFailure.permissionDenied,
        ),
      );

      await tester.tap(find.widgetWithText(FilterChip, '내 위치'));
      await tester.pumpAndSettle();

      expect(find.text('현재 위치 권한을 허용해 주세요.'), findsOneWidget);
      expect(find.text('성북구립도서관'), findsOneWidget);
      expect(Get.find<PlacesController>().usingCurrentLocation, isFalse);

      // 스낵바는 3초 뒤 스스로 닫힙니다. 그 타이머를 남겨 두면
      // 테스트 종료 시점에 "Timer is still pending"으로 실패합니다.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('지도로 바꾸면 검색 결과를 마커로 넘긴다', (tester) async {
      await _pumpApp(tester, places: const [samplePlace]);

      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();

      expect(find.text('마커 성북구립도서관'), findsOneWidget);
      expect(find.text('지도 중심 37.592, 127.016'), findsOneWidget);
      // 목록은 더 보이지 않습니다.
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('마커를 누르면 장소 상세로 이동한다', (tester) async {
      await _pumpApp(tester, places: const [samplePlace]);
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('마커 성북구립도서관'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.placeDetail(samplePlace.id));
    });

    testWidgets('이 지역 재검색은 지도 중심으로 다시 검색한다', (tester) async {
      await _pumpApp(tester, places: const [samplePlace]);
      final repository = Get.find<PlacesRepository>() as _StubPlacesRepository;
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('이 지역 재검색'));
      await tester.pumpAndSettle();

      expect(repository.lastQuery?.lat, 37.55);
      expect(repository.lastQuery?.lng, 126.99);
    });

    testWidgets('지도에서 목록으로 되돌릴 수 있다', (tester) async {
      await _pumpApp(tester, places: const [samplePlace]);
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      expect(find.text('마커 성북구립도서관'), findsNothing);
      expect(find.text('성북구립도서관'), findsOneWidget);
    });
  });

  group('장소 상세', () {
    Future<void> openDetail(WidgetTester tester) async {
      await _pumpApp(tester, places: const [samplePlace]);
      await tester.tap(find.text('성북구립도서관'));
      await tester.pumpAndSettle();
    }

    /// 후기 구역은 화면 밖에 있어 먼저 스크롤해야 만들어집니다.
    Future<void> openReviews(
      WidgetTester tester, {
      bool signedIn = false,
      List<Map<String, dynamic>> reviews = const [],
    }) async {
      await _pumpApp(
        tester,
        places: const [samplePlace],
        signedIn: signedIn,
        reviews: reviews,
      );
      await tester.tap(find.text('성북구립도서관'));
      await tester.pumpAndSettle();
      await _scrollListTo(tester, find.text('방문자 후기'));
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

    testWidgets('로그아웃 상태에서는 후기 대신 로그인을 안내한다', (tester) async {
      await openReviews(tester);

      expect(find.text('로그인하면 후기와 평점을 남길 수 있습니다.'), findsOneWidget);
      expect(find.text('아직 후기가 없습니다.'), findsOneWidget);
      expect(find.text('평점 없음'), findsOneWidget);
      // 작성 폼은 보이지 않습니다.
      expect(find.widgetWithText(FilledButton, '후기 등록'), findsNothing);
    });

    testWidgets('서버가 준 후기와 평균 별점을 보여준다', (tester) async {
      await openReviews(
        tester,
        reviews: const [
          {
            'id': 5,
            'userId': 99,
            'username': 'someone',
            'rating': 4,
            'comment': '조용해서 좋았어요',
            'createdAt': '2026-08-28T23:04:11.123',
          },
        ],
      );

      expect(find.text('someone'), findsOneWidget);
      expect(find.text('조용해서 좋았어요'), findsOneWidget);
      expect(find.text('2026.08.28'), findsOneWidget);
      expect(find.text('4.0 / 5.0'), findsOneWidget);
      expect(find.text('(1개)'), findsOneWidget);
    });

    testWidgets('로그인 상태에서 후기를 등록하면 목록에 나타난다', (tester) async {
      await openReviews(tester, signedIn: true);
      final repository = Get.find<PlacesRepository>() as _StubPlacesRepository;

      await tester.enterText(find.byType(TextField), '조용하고 좋았어요');
      final submitButton = find.widgetWithText(FilledButton, '후기 등록');
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // 별점은 기본값 5점으로 보냅니다.
      expect(repository.lastCreatedReview?.rating, 5);
      expect(repository.lastCreatedReview?.comment, '조용하고 좋았어요');
      await _scrollListTo(tester, find.text('조용하고 좋았어요'));
      expect(find.text('조용하고 좋았어요'), findsOneWidget);
    });

    testWidgets('별점을 골라서 등록할 수 있다', (tester) async {
      await openReviews(tester, signedIn: true);
      final repository = Get.find<PlacesRepository>() as _StubPlacesRepository;

      // 폼의 별 버튼 중 세 번째를 누릅니다.
      await tester.tap(find.byTooltip('3점'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '보통이었어요');
      final submitButton = find.widgetWithText(FilledButton, '후기 등록');
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(repository.lastCreatedReview?.rating, 3);
    });

    testWidgets('빈 후기는 서버를 부르지 않고 막는다', (tester) async {
      await openReviews(tester, signedIn: true);
      final repository = Get.find<PlacesRepository>() as _StubPlacesRepository;

      final submitButton = find.widgetWithText(FilledButton, '후기 등록');
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(repository.lastCreatedReview, isNull);
      await tester.ensureVisible(find.text('후기 내용을 입력해 주세요.'));
      expect(find.text('후기 내용을 입력해 주세요.'), findsOneWidget);
    });

    testWidgets('내 후기만 삭제 버튼을 보여준다', (tester) async {
      // 로그인한 테스트 사용자의 id는 1입니다.
      await openReviews(
        tester,
        signedIn: true,
        reviews: const [
          {
            'id': 5,
            'userId': 1,
            'username': 'teumsae_user',
            'rating': 5,
            'comment': '내가 쓴 후기',
            'createdAt': '2026-08-28T23:04:11.123',
          },
          {
            'id': 6,
            'userId': 99,
            'username': 'someone',
            'rating': 3,
            'comment': '남이 쓴 후기',
            'createdAt': '2026-08-27T10:00:00.000',
          },
        ],
      );

      // 서버도 본인 후기만 삭제를 허용합니다. 지울 수 없는 버튼을 보여 주고
      // 403을 받게 하지 않습니다.
      await _scrollListTo(tester, find.text('남이 쓴 후기'));
      expect(find.widgetWithText(TextButton, '삭제'), findsOneWidget);
    });

    testWidgets('후기 삭제는 한 번 더 확인한다', (tester) async {
      await openReviews(
        tester,
        signedIn: true,
        reviews: const [
          {
            'id': 5,
            'userId': 1,
            'username': 'teumsae_user',
            'rating': 5,
            'comment': '내가 쓴 후기',
            'createdAt': '2026-08-28T23:04:11.123',
          },
        ],
      );

      final tileDeleteButton = find.widgetWithText(TextButton, '삭제');
      final dialogDeleteButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, '삭제'),
      );

      await tester.ensureVisible(tileDeleteButton);
      await tester.pumpAndSettle();
      await tester.tap(tileDeleteButton);
      await tester.pumpAndSettle();
      expect(find.text('후기를 삭제할까요?'), findsOneWidget);

      // 취소하면 남아 있습니다.
      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pumpAndSettle();
      expect(find.text('내가 쓴 후기'), findsOneWidget);

      await tester.ensureVisible(tileDeleteButton);
      await tester.pumpAndSettle();
      await tester.tap(tileDeleteButton);
      await tester.pumpAndSettle();
      await tester.tap(dialogDeleteButton);
      await tester.pumpAndSettle();

      expect(find.text('내가 쓴 후기'), findsNothing);
      await _scrollListTo(tester, find.text('아직 후기가 없습니다.'));
      expect(find.text('아직 후기가 없습니다.'), findsOneWidget);
    });
  });

  group('장소 등록·수정', () {
    testWidgets('로그인하지 않으면 등록 화면을 열 수 없다', (tester) async {
      await _pumpApp(tester, initialRoute: AppRoutes.placeNew);

      expect(Get.currentRoute, AppRoutes.login);
    });

    testWidgets('등록 화면은 빈 이름을 서버 없이 막는다', (tester) async {
      await _pumpApp(
        tester,
        initialRoute: AppRoutes.placeNew,
        signedIn: true,
      );
      final repository = Get.find<PlacesRepository>() as _StubPlacesRepository;

      final submit = find.widgetWithText(FilledButton, '장소 등록');
      await _scrollListTo(tester, submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(repository.lastCreatedPlace, isNull);
      // 안내 문구는 폼 맨 위에 붙습니다. 버튼까지 내려온 뒤라 올라가며 찾습니다.
      await _scrollListTo(
        tester,
        find.text('장소 이름을 입력해 주세요.'),
        delta: -300,
      );
      expect(find.text('장소 이름을 입력해 주세요.'), findsOneWidget);
    });

    testWidgets('이름을 넣고 등록하면 상세로 이동한다', (tester) async {
      await _pumpApp(
        tester,
        initialRoute: AppRoutes.placeNew,
        signedIn: true,
      );
      final repository = Get.find<PlacesRepository>() as _StubPlacesRepository;

      await tester.enterText(find.byType(TextField).first, '틈새 쉼터');
      final submit = find.widgetWithText(FilledButton, '장소 등록');
      await _scrollListTo(tester, submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(repository.lastCreatedPlace?['name'], '틈새 쉼터');
      // 기본값은 웹 폼과 같습니다.
      expect(repository.lastCreatedPlace?['type'], 'PUBLIC_FACILITY');
      expect(repository.lastCreatedPlace?['priceLevel'], 'FREE');
      expect(Get.currentRoute, AppRoutes.placeDetail(99));
    });

    testWidgets('지도에서 위치를 고르면 좌표와 주소가 바뀐다', (tester) async {
      await _pumpApp(
        tester,
        initialRoute: AppRoutes.placeNew,
        signedIn: true,
      );

      await _scrollListTo(tester, find.text('지도에서 위치 고르기'));
      await tester.tap(find.text('지도에서 위치 고르기'));
      await tester.pumpAndSettle();

      final controller = Get.find<PlaceFormController>();
      expect(controller.values.lat, 37.55);
      expect(controller.values.lng, 126.99);
      // 주소를 비워 뒀으면 서버가 찾아 준 값을 채웁니다.
      expect(controller.values.address, '서울 성북구 화랑로 123');
    });

    testWidgets('수정 화면은 기존 값을 채워서 연다', (tester) async {
      await _pumpApp(
        tester,
        initialRoute: AppRoutes.placeEdit(5),
        signedIn: true,
      );

      final controller = Get.find<PlaceFormController>();
      expect(controller.isEditing, isTrue);
      expect(controller.values.name, '성북구립도서관');
      expect(find.text('장소 수정'), findsOneWidget);
      await _scrollListTo(tester, find.widgetWithText(FilledButton, '수정 저장'));
      expect(find.widgetWithText(FilledButton, '수정 저장'), findsOneWidget);
    });
  });

  group('내가 등록한 장소', () {
    testWidgets('로그인하지 않으면 열 수 없다', (tester) async {
      await _pumpApp(tester, initialRoute: AppRoutes.myPlaces);

      expect(Get.currentRoute, AppRoutes.login);
    });

    testWidgets('등록한 장소를 보여주고 수정으로 갈 수 있다', (tester) async {
      await _pumpApp(
        tester,
        initialRoute: AppRoutes.myPlaces,
        signedIn: true,
      );

      expect(find.text('성북구립도서관'), findsWidgets);

      await tester.tap(find.widgetWithText(TextButton, '수정').first);
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.placeEdit(1));
    });

    testWidgets('삭제는 한 번 더 확인하고 목록에서 지운다', (tester) async {
      await _pumpApp(
        tester,
        initialRoute: AppRoutes.myPlaces,
        signedIn: true,
      );
      final controller = Get.find<MyPlacesController>();
      expect(controller.places, hasLength(2));

      await tester.tap(find.widgetWithText(TextButton, '삭제').first);
      await tester.pumpAndSettle();
      expect(find.text('장소를 삭제할까요?'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, '삭제'),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.places, hasLength(1));
    });

    testWidgets('내 정보 탭에서 들어갈 수 있다', (tester) async {
      await _pumpApp(tester, signedIn: true);
      await tester.tap(_tab('내 정보'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, '내가 등록한 장소'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.myPlaces);
    });
  });

  group('공개 프로필', () {
    testWidgets('로그인 없이도 프로필을 볼 수 있다', (tester) async {
      await _pumpApp(
        tester,
        initialRoute: AppRoutes.userProfile('jason'),
        profile: const {
          'id': 99,
          'username': 'jason',
          'createdAt': '2026-01-02T10:00:00.000',
          'registeredPlacesCount': 1,
          'reviewsCount': 1,
          'registeredPlaces': [
            {'id': 3, 'name': '성북구립도서관', 'typeLabel': '도서관'},
          ],
          'reviews': [
            {
              'id': 5,
              'placeId': 3,
              'placeName': '성북구립도서관',
              'rating': 4,
              'comment': '조용해요',
              'createdAt': '2026-08-28T23:04:11.123',
            },
          ],
        },
      );

      expect(find.text('jason'), findsOneWidget);
      expect(find.text('2026년 1월 2일 가입'), findsOneWidget);
      expect(find.text('등록한 틈새 (1)'), findsOneWidget);
      expect(find.text('작성한 후기 (1)'), findsOneWidget);
      expect(find.text('조용해요'), findsOneWidget);
      // 로그인하지 않으면 차단·신고를 보여 주지 않습니다.
      expect(find.text('이 사용자 차단'), findsNothing);
    });

    testWidgets('로그인하면 차단·신고를 보여준다', (tester) async {
      await _pumpApp(
        tester,
        initialRoute: AppRoutes.userProfile('jason'),
        signedIn: true,
      );

      expect(find.text('이 사용자 차단'), findsOneWidget);
      expect(find.text('이 사용자 신고'), findsOneWidget);
    });

    testWidgets('차단하면 안내와 해제 버튼으로 바뀐다', (tester) async {
      await _pumpApp(
        tester,
        initialRoute: AppRoutes.userProfile('jason'),
        signedIn: true,
      );

      await tester.tap(find.text('이 사용자 차단'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '차단'));
      await tester.pumpAndSettle();

      expect(Get.find<BlockController>().isBlocked(99), isTrue);
      expect(find.text('차단한 사용자입니다.'), findsOneWidget);
      expect(find.text('차단 해제'), findsOneWidget);
    });

    testWidgets('신고 사유를 적어 보낸다', (tester) async {
      await _pumpApp(
        tester,
        initialRoute: AppRoutes.userProfile('jason'),
        signedIn: true,
      );
      final repository = Get.find<UsersRepository>() as _StubUsersRepository;

      await tester.tap(find.text('이 사용자 신고'));
      await tester.pumpAndSettle();
      // 자주 쓰는 사유를 눌러 채울 수 있습니다.
      await tester.tap(find.widgetWithText(ActionChip, '스팸'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '신고하기'));
      await tester.pumpAndSettle();

      expect(repository.lastReport?.target, 'USER');
      expect(repository.lastReport?.id, 99);
      expect(repository.lastReport?.reason, '스팸');

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('빈 사유는 시트에서 막는다', (tester) async {
      await _pumpApp(
        tester,
        initialRoute: AppRoutes.userProfile('jason'),
        signedIn: true,
      );
      final repository = Get.find<UsersRepository>() as _StubUsersRepository;

      await tester.tap(find.text('이 사용자 신고'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '신고하기'));
      await tester.pumpAndSettle();

      expect(repository.lastReport, isNull);
      expect(find.text('신고 사유를 입력해 주세요.'), findsOneWidget);
    });
  });

  group('후기 신고·차단', () {
    const othersReview = {
      'id': 6,
      'userId': 99,
      'username': 'someone',
      'rating': 3,
      'comment': '남이 쓴 후기',
      'createdAt': '2026-08-27T10:00:00.000',
    };

    testWidgets('작성자 이름을 누르면 공개 프로필로 간다', (tester) async {
      await _pumpApp(
        tester,
        places: const [samplePlace],
        reviews: const [othersReview],
      );
      await tester.tap(find.text('성북구립도서관'));
      await tester.pumpAndSettle();
      await _scrollListTo(tester, find.text('someone'));
      await tester.ensureVisible(find.text('someone'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('someone'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.userProfile('someone'));
    });

    testWidgets('남의 후기는 신고·차단 메뉴를 보여준다', (tester) async {
      await _pumpApp(
        tester,
        places: const [samplePlace],
        signedIn: true,
        reviews: const [othersReview],
      );
      await tester.tap(find.text('성북구립도서관'));
      await tester.pumpAndSettle();
      await _scrollListTo(tester, find.text('남이 쓴 후기'));
      await tester.ensureVisible(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('신고'), findsOneWidget);
      expect(find.text('차단'), findsOneWidget);
    });

    testWidgets('차단하면 그 사용자의 후기가 목록에서 사라진다', (tester) async {
      await _pumpApp(
        tester,
        places: const [samplePlace],
        signedIn: true,
        reviews: const [othersReview],
      );
      await tester.tap(find.text('성북구립도서관'));
      await tester.pumpAndSettle();
      await _scrollListTo(tester, find.text('남이 쓴 후기'));
      await tester.ensureVisible(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('차단'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '차단'));
      await tester.pumpAndSettle();

      // 서버는 그대로 주지만 앱에서 걸러 냅니다.
      expect(find.text('남이 쓴 후기'), findsNothing);
      expect(find.text('아직 후기가 없습니다.'), findsOneWidget);
    });

    testWidgets('차단한 사용자의 후기는 처음부터 보이지 않는다', (tester) async {
      await _pumpApp(
        tester,
        places: const [samplePlace],
        signedIn: true,
        reviews: const [othersReview],
        blockedIds: const {99},
      );
      await tester.tap(find.text('성북구립도서관'));
      await tester.pumpAndSettle();
      await _scrollListTo(tester, find.text('방문자 후기'));

      expect(find.text('남이 쓴 후기'), findsNothing);
    });

    testWidgets('내 후기에는 신고·차단이 없다', (tester) async {
      await _pumpApp(
        tester,
        places: const [samplePlace],
        signedIn: true,
        reviews: const [
          {
            'id': 5,
            'userId': 1,
            'username': 'teumsae_user',
            'rating': 5,
            'comment': '내가 쓴 후기',
            'createdAt': '2026-08-28T23:04:11.123',
          },
        ],
      );
      await tester.tap(find.text('성북구립도서관'));
      await tester.pumpAndSettle();
      await _scrollListTo(tester, find.text('내가 쓴 후기'));

      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(find.widgetWithText(TextButton, '삭제'), findsOneWidget);
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
