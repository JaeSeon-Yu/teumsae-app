import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/core/network/api_client.dart';
import 'package:teumsae_app/src/core/network/api_exception.dart';
import 'package:teumsae_app/src/core/storage/token_store.dart';
import 'package:teumsae_app/src/features/places/place_summary.dart';
import 'package:teumsae_app/src/features/places/places_controller.dart';
import 'package:teumsae_app/src/features/places/places_repository.dart';

const _place = PlaceSummary(
  id: 1,
  name: '성북구립도서관',
  typeLabel: '도서관',
  address: '서울 성북구 화랑로',
  distanceMeters: 420,
  priceLabel: '무료',
  restScore: 87,
  scoreLabel: '아주 좋아요',
  reasons: ['조용해요'],
  tags: ['wifi'],
);

class _StubPlacesRepository extends PlacesRepository {
  _StubPlacesRepository({this.error})
      : super(ApiClient(tokenStore: InMemoryTokenStore()));

  final Object? error;

  /// 마지막으로 요청된 조건. 조건 변경이 실제 검색에 반영됐는지 확인합니다.
  PlaceSearchQuery? lastQuery;
  int callCount = 0;

  @override
  Future<List<PlaceSummary>> search(PlaceSearchQuery query) async {
    lastQuery = query;
    callCount++;
    if (error != null) throw error!;
    return const [_place];
  }
}

void main() {
  test('검색 성공 시 목록을 채운다', () async {
    final controller = PlacesController(_StubPlacesRepository());

    await controller.search();

    expect(controller.places, hasLength(1));
    expect(controller.places.first.name, '성북구립도서관');
    expect(controller.errorMessage, isNull);
    expect(controller.isLoading, isFalse);
  });

  test('서버 에러 메시지를 그대로 노출하고 목록을 비운다', () async {
    final controller = PlacesController(
      _StubPlacesRepository(
        error: const ApiException(
          statusCode: 400,
          message: 'radius must be between 100 and 5000.',
        ),
      ),
    );

    await controller.search();

    expect(controller.places, isEmpty);
    expect(controller.errorMessage, 'radius must be between 100 and 5000.');
  });

  test('기본 조건은 웹과 같은 값을 쓴다', () async {
    final repository = _StubPlacesRepository();
    final controller = PlacesController(repository);

    await controller.search();

    expect(repository.lastQuery?.lat, 37.592);
    expect(repository.lastQuery?.lng, 127.016);
    expect(repository.lastQuery?.radius, 1500);
    expect(repository.lastQuery?.theme, 'REST');
  });

  test('테마를 바꾸면 새 조건으로 다시 검색한다', () async {
    final repository = _StubPlacesRepository();
    final controller = PlacesController(repository);
    await controller.search();

    await controller.changeTheme('TOILET');

    expect(controller.query.theme, 'TOILET');
    expect(repository.lastQuery?.theme, 'TOILET');
    expect(repository.callCount, 2);
  });

  test('같은 테마를 다시 누르면 재검색하지 않는다', () async {
    final repository = _StubPlacesRepository();
    final controller = PlacesController(repository);
    await controller.search();

    await controller.changeTheme('REST');

    expect(repository.callCount, 1);
  });
}
