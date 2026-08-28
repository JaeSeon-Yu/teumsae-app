import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/core/network/api_client.dart';
import 'package:teumsae_app/src/core/network/api_exception.dart';
import 'package:teumsae_app/src/core/storage/token_store.dart';
import 'package:teumsae_app/src/features/places/place_detail.dart';
import 'package:teumsae_app/src/features/places/place_detail_controller.dart';
import 'package:teumsae_app/src/features/places/places_repository.dart';

PlaceDetail _place(int id) => PlaceDetail.fromJson({
      'id': id,
      'name': '성북구립도서관',
      'typeLabel': '도서관',
      'openStatusLabel': '영업중',
    });

class _StubPlacesRepository extends PlacesRepository {
  _StubPlacesRepository({this.error})
      : super(ApiClient(tokenStore: InMemoryTokenStore()));

  final Object? error;

  int? lastRequestedId;
  int callCount = 0;

  @override
  Future<PlaceDetail> getPlace(int id) async {
    lastRequestedId = id;
    callCount++;
    if (error != null) throw error!;
    return _place(id);
  }
}

void main() {
  test('라우트로 받은 id로 조회한다', () async {
    final repository = _StubPlacesRepository();
    final controller = PlaceDetailController(repository: repository, id: 12);

    await controller.load();

    expect(repository.lastRequestedId, 12);
    expect(controller.place?.name, '성북구립도서관');
    expect(controller.errorMessage, isNull);
    expect(controller.isLoading, isFalse);
  });

  test('404는 없는 장소 안내로 바꾼다', () async {
    // 서버 404 메시지는 영문일 수 있어 화면 문구를 앱에서 정합니다.
    final controller = PlaceDetailController(
      repository: _StubPlacesRepository(
        error: const ApiException(statusCode: 404, message: 'Place not found'),
      ),
      id: 999,
    );

    await controller.load();

    expect(controller.place, isNull);
    expect(controller.errorMessage, '없는 장소이거나 삭제된 장소입니다.');
  });

  test('그 밖의 서버 에러는 메시지를 그대로 노출한다', () async {
    final controller = PlaceDetailController(
      repository: _StubPlacesRepository(
        error: const ApiException(statusCode: 500, message: '서버 오류가 발생했습니다.'),
      ),
      id: 1,
    );

    await controller.load();

    expect(controller.errorMessage, '서버 오류가 발생했습니다.');
  });

  test('예상 못 한 예외도 화면용 문구로 바꾼다', () async {
    final controller = PlaceDetailController(
      repository: _StubPlacesRepository(error: StateError('boom')),
      id: 1,
    );

    await controller.load();

    expect(controller.errorMessage, '장소 정보를 불러오지 못했습니다.');
  });

  test('다시 시도하면 재조회한다', () async {
    final repository = _StubPlacesRepository();
    final controller = PlaceDetailController(repository: repository, id: 3);
    await controller.load();

    await controller.load();

    expect(repository.callCount, 2);
    expect(controller.errorMessage, isNull);
  });
}
