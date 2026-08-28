import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/core/location/location_service.dart';
import 'package:teumsae_app/src/core/network/api_client.dart';
import 'package:teumsae_app/src/core/network/api_exception.dart';
import 'package:teumsae_app/src/core/storage/token_store.dart';
import 'package:teumsae_app/src/features/places/place_search_query.dart';
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
  scoreLabel: '지금 딱 좋음',
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

/// 위치 조회가 끝나는 시점을 테스트가 정할 수 있는 구현.
/// (조회 중 버튼 잠금을 확인하려면 응답을 붙잡아 둘 수 있어야 합니다)
class _ControlledLocationService implements LocationService {
  final _pending = Completer<UserLocation>();
  int callCount = 0;

  @override
  Future<UserLocation> current() {
    callCount++;
    return _pending.future;
  }

  void complete(UserLocation location) => _pending.complete(location);
}

PlacesController _controller(
  PlacesRepository repository, {
  LocationService? location,
}) {
  return PlacesController(
    repository: repository,
    location: location ??
        const FixedLocationService(UserLocation(lat: 37.5, lng: 127.1)),
  );
}

void main() {
  test('검색 성공 시 목록을 채운다', () async {
    final controller = _controller(_StubPlacesRepository());

    await controller.search();

    expect(controller.places, hasLength(1));
    expect(controller.places.first.name, '성북구립도서관');
    expect(controller.errorMessage, isNull);
    expect(controller.isLoading, isFalse);
  });

  test('서버 에러 메시지를 그대로 노출하고 목록을 비운다', () async {
    final controller = _controller(
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
    final controller = _controller(repository);

    await controller.search();

    expect(repository.lastQuery?.lat, 37.592);
    expect(repository.lastQuery?.lng, 127.016);
    expect(repository.lastQuery?.radius, 1500);
    expect(repository.lastQuery?.stayMinutes, 0);
    expect(repository.lastQuery?.theme, SearchTheme.rest);
    expect(repository.lastQuery?.budget, SearchBudget.any);
    expect(repository.lastQuery?.space, SearchSpace.any);
    expect(repository.lastQuery?.needs, isEmpty);
    expect(repository.lastQuery?.sort, SearchSort.recommended);
    expect(repository.lastQuery?.openOnly, isFalse);
  });

  test('테마를 바꾸면 새 조건으로 다시 검색한다', () async {
    final repository = _StubPlacesRepository();
    final controller = _controller(repository);
    await controller.search();

    await controller.changeTheme(SearchTheme.toilet);

    expect(controller.query.theme, SearchTheme.toilet);
    expect(repository.lastQuery?.theme, SearchTheme.toilet);
    expect(repository.callCount, 2);
  });

  test('같은 테마를 다시 누르면 재검색하지 않는다', () async {
    final repository = _StubPlacesRepository();
    final controller = _controller(repository);
    await controller.search();

    await controller.changeTheme(SearchTheme.rest);

    expect(repository.callCount, 1);
  });

  test('정렬을 바꾸면 다시 검색한다', () async {
    final repository = _StubPlacesRepository();
    final controller = _controller(repository);
    await controller.search();

    await controller.changeSort(SearchSort.distance);

    expect(repository.lastQuery?.sort, SearchSort.distance);
    expect(repository.callCount, 2);

    // 같은 값이면 재검색하지 않습니다.
    await controller.changeSort(SearchSort.distance);
    expect(repository.callCount, 2);
  });

  test('영업중만 토글은 켜고 끌 때마다 다시 검색한다', () async {
    final repository = _StubPlacesRepository();
    final controller = _controller(repository);
    await controller.search();

    await controller.toggleOpenOnly();
    expect(repository.lastQuery?.openOnly, isTrue);

    await controller.toggleOpenOnly();
    expect(repository.lastQuery?.openOnly, isFalse);
    expect(repository.callCount, 3);
  });

  test('조건 시트에서 만든 조건을 한 번에 적용한다', () async {
    final repository = _StubPlacesRepository();
    final controller = _controller(repository);
    await controller.search();

    await controller.applyFilters(
      controller.query.copyWith(
        radius: 3000,
        stayMinutes: 60,
        budget: SearchBudget.free,
        space: SearchSpace.indoor,
        needs: {SearchNeed.wifi, SearchNeed.quiet},
      ),
    );

    // 여러 항목을 바꿨어도 요청은 한 번만 늘어납니다.
    expect(repository.callCount, 2);
    expect(repository.lastQuery?.radius, 3000);
    expect(repository.lastQuery?.budget, SearchBudget.free);
    expect(repository.lastQuery?.needs, {SearchNeed.wifi, SearchNeed.quiet});
  });

  group('현재 위치', () {
    test('현재 위치를 받으면 그 좌표로 다시 검색한다', () async {
      final repository = _StubPlacesRepository();
      final controller = _controller(repository);
      await controller.search();

      await controller.useCurrentLocation();

      expect(controller.usingCurrentLocation, isTrue);
      expect(controller.locationError, isNull);
      expect(controller.isLocating, isFalse);
      expect(repository.lastQuery?.lat, 37.5);
      expect(repository.lastQuery?.lng, 127.1);
      expect(repository.callCount, 2);
    });

    test('좌표만 바뀌고 다른 조건은 그대로 유지된다', () async {
      final repository = _StubPlacesRepository();
      final controller = _controller(repository);
      await controller.search();
      await controller.applyFilters(
        controller.query.copyWith(radius: 500, needs: {SearchNeed.wifi}),
      );

      await controller.useCurrentLocation();

      expect(repository.lastQuery?.radius, 500);
      expect(repository.lastQuery?.needs, {SearchNeed.wifi});
      expect(repository.lastQuery?.theme, SearchTheme.rest);
    });

    test('권한을 거부하면 좌표를 그대로 두고 문구만 남긴다', () async {
      final repository = _StubPlacesRepository();
      final controller = _controller(
        repository,
        location: const FailingLocationService(
          LocationFailure.permissionDenied,
        ),
      );
      await controller.search();

      await controller.useCurrentLocation();

      expect(controller.usingCurrentLocation, isFalse);
      expect(controller.locationError, '현재 위치 권한을 허용해 주세요.');
      // 검색 결과는 그대로 남습니다. 지우면 아무것도 볼 수 없게 됩니다.
      expect(controller.places, hasLength(1));
      expect(repository.lastQuery?.lat, 37.592);
      expect(repository.callCount, 1);
    });

    test('위치 서비스가 꺼져 있으면 그 상황에 맞는 문구를 쓴다', () async {
      final controller = _controller(
        _StubPlacesRepository(),
        location: const FailingLocationService(
          LocationFailure.serviceDisabled,
        ),
      );

      await controller.useCurrentLocation();

      expect(controller.locationError, '기기의 위치 서비스가 꺼져 있습니다.');
    });

    test('실패 문구는 화면에서 보여 준 뒤 지울 수 있다', () async {
      final controller = _controller(
        _StubPlacesRepository(),
        location: const FailingLocationService(LocationFailure.unavailable),
      );
      await controller.useCurrentLocation();

      controller.clearLocationError();

      expect(controller.locationError, isNull);
    });

    test('기본 좌표로 되돌리면 다시 검색한다', () async {
      final repository = _StubPlacesRepository();
      final controller = _controller(repository);
      await controller.search();
      await controller.useCurrentLocation();

      await controller.useDefaultLocation();

      expect(controller.usingCurrentLocation, isFalse);
      expect(repository.lastQuery?.lat, 37.592);
      expect(repository.lastQuery?.lng, 127.016);
      expect(repository.callCount, 3);
    });

    test('이미 기본 좌표면 되돌려도 재검색하지 않는다', () async {
      final repository = _StubPlacesRepository();
      final controller = _controller(repository);
      await controller.search();

      await controller.useDefaultLocation();

      expect(repository.callCount, 1);
    });

    test('조회 중에 다시 부르면 요청이 겹치지 않는다', () async {
      final location = _ControlledLocationService();
      final repository = _StubPlacesRepository();
      final controller = _controller(repository, location: location);
      await controller.search();

      final first = controller.useCurrentLocation();
      expect(controller.isLocating, isTrue);

      // 아직 첫 조회가 끝나지 않았으므로 두 번째 호출은 그대로 끝납니다.
      await controller.useCurrentLocation();
      expect(location.callCount, 1);

      location.complete(const UserLocation(lat: 35.1, lng: 129.0));
      await first;

      expect(controller.isLocating, isFalse);
      expect(repository.lastQuery?.lat, 35.1);
    });
  });
}
