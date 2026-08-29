import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/core/network/api_client.dart';
import 'package:teumsae_app/src/core/network/api_exception.dart';
import 'package:teumsae_app/src/core/storage/token_store.dart';
import 'package:teumsae_app/src/features/places/my_places_controller.dart';
import 'package:teumsae_app/src/features/places/place_detail.dart';
import 'package:teumsae_app/src/features/places/place_form.dart';
import 'package:teumsae_app/src/features/places/place_form_controller.dart';
import 'package:teumsae_app/src/features/places/places_repository.dart';

PlaceDetail _detail({int id = 1, Map<String, dynamic> overrides = const {}}) =>
    PlaceDetail.fromJson({
      'id': id,
      'name': '성북구립도서관',
      'type': 'LIBRARY',
      'address': '서울 성북구 화랑로',
      'lat': 37.5921,
      'lng': 127.0161,
      'priceLevel': 'FREE',
      'indoor': true,
      'stayMinutesMin': 30,
      'stayMinutesMax': 180,
      ...overrides,
    });

class _StubPlacesRepository extends PlacesRepository {
  _StubPlacesRepository({this.writeError, this.listError})
      : super(ApiClient(tokenStore: InMemoryTokenStore()));

  /// 등록·수정·삭제에서 던질 예외.
  final Object? writeError;

  /// 목록·상세 조회에서 던질 예외.
  final Object? listError;

  Map<String, dynamic>? lastCreated;
  ({int id, Map<String, dynamic> body})? lastUpdated;
  int? lastDeletedId;
  int tagCallCount = 0;
  int myPlacesCallCount = 0;
  String? stubbedAddress = '서울 성북구 화랑로 123';

  @override
  Future<PlaceDetail> getPlace(int id) async {
    if (listError != null) throw listError!;
    return _detail(id: id);
  }

  @override
  Future<List<PlaceTagOption>> tags() async {
    tagCallCount++;
    return const [
      PlaceTagOption(name: 'INDOOR', label: '실내'),
      PlaceTagOption(name: 'WIFI', label: '와이파이'),
    ];
  }

  @override
  Future<PlaceDetail> createPlace(Map<String, dynamic> body) async {
    lastCreated = body;
    if (writeError != null) throw writeError!;
    return _detail(id: 42);
  }

  @override
  Future<PlaceDetail> updatePlace(int id, Map<String, dynamic> body) async {
    lastUpdated = (id: id, body: body);
    if (writeError != null) throw writeError!;
    return _detail(id: id);
  }

  @override
  Future<void> deletePlace(int id) async {
    lastDeletedId = id;
    if (writeError != null) throw writeError!;
  }

  @override
  Future<List<PlaceDetail>> myPlaces() async {
    myPlacesCallCount++;
    if (listError != null) throw listError!;
    return [_detail(id: 1), _detail(id: 2)];
  }

  @override
  Future<String?> reverseGeocode(double lat, double lng) async =>
      stubbedAddress;
}

void main() {
  group('등록 폼', () {
    test('태그 목록을 받아 둔다', () async {
      final repository = _StubPlacesRepository();
      final controller = PlaceFormController(repository: repository);

      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(repository.tagCallCount, 1);
      expect(controller.tagOptions, hasLength(2));
      expect(controller.isEditing, isFalse);
      expect(controller.title, '장소 등록');
    });

    test('검증에 걸리면 서버를 부르지 않는다', () async {
      final repository = _StubPlacesRepository();
      final controller = PlaceFormController(repository: repository);

      final id = await controller.submit();

      expect(id, isNull);
      expect(repository.lastCreated, isNull);
      expect(controller.errorMessage, '장소 이름을 입력해 주세요.');
    });

    test('등록에 성공하면 새 장소 id를 준다', () async {
      final repository = _StubPlacesRepository();
      final controller = PlaceFormController(repository: repository);
      controller.updateValues(const PlaceFormValues(name: '틈새 쉼터'));

      final id = await controller.submit();

      expect(id, 42);
      expect(repository.lastCreated?['name'], '틈새 쉼터');
      expect(controller.errorMessage, isNull);
    });

    test('서버 에러 메시지를 그대로 노출한다', () async {
      // 중복 등록은 서버가 한글 메시지로 알려 줍니다.
      final controller = PlaceFormController(
        repository: _StubPlacesRepository(
          writeError: const ApiException(
            statusCode: 409,
            message: '이미 등록된 장소입니다.',
          ),
        ),
      );
      controller.updateValues(const PlaceFormValues(name: '틈새 쉼터'));

      final id = await controller.submit();

      expect(id, isNull);
      expect(controller.errorMessage, '이미 등록된 장소입니다.');
    });

    test('태그를 켜면 편의시설 플래그도 함께 움직인다', () {
      final controller = PlaceFormController(
        repository: _StubPlacesRepository(),
      );

      controller.toggleTag('와이파이');

      expect(controller.values.tags, {'와이파이'});
      expect(controller.values.wifi, isTrue);

      controller.toggleTag('와이파이');
      expect(controller.values.tags, isEmpty);
      expect(controller.values.wifi, isFalse);
    });

    test('태그 9개째는 막고 안내한다', () {
      final controller = PlaceFormController(
        repository: _StubPlacesRepository(),
      );
      for (var i = 0; i < 8; i++) {
        controller.toggleTag('태그$i');
      }

      controller.toggleTag('태그8');

      expect(controller.values.tags, hasLength(8));
      expect(controller.errorMessage, '태그는 8개까지 고를 수 있습니다.');
    });

    test('핀을 옮기면 좌표가 바뀌고 주소를 찾아 채운다', () async {
      final controller = PlaceFormController(
        repository: _StubPlacesRepository(),
      );

      await controller.movePin(37.55, 126.99);

      expect(controller.values.lat, 37.55);
      expect(controller.values.lng, 126.99);
      expect(controller.values.address, '서울 성북구 화랑로 123');
      expect(controller.isResolvingAddress, isFalse);
    });

    test('직접 적은 주소는 핀을 옮겨도 덮어쓰지 않는다', () async {
      final controller = PlaceFormController(
        repository: _StubPlacesRepository(),
      );
      controller.updateValues(
        const PlaceFormValues(name: '틈새', address: '내가 적은 주소'),
      );

      await controller.movePin(37.55, 126.99);

      expect(controller.values.address, '내가 적은 주소');
      expect(controller.values.lat, 37.55);
    });
  });

  group('수정 폼', () {
    test('기존 값을 불러와 채운다', () async {
      final controller = PlaceFormController(
        repository: _StubPlacesRepository(),
        placeId: 7,
      );

      await controller.loadPlace();

      expect(controller.isEditing, isTrue);
      expect(controller.title, '장소 수정');
      expect(controller.values.name, '성북구립도서관');
      expect(controller.values.type, PlaceTypeOption.library);
    });

    test('없는 장소는 안내 문구로 바꾼다', () async {
      final controller = PlaceFormController(
        repository: _StubPlacesRepository(
          listError: const ApiException(
            statusCode: 404,
            message: 'Place not found',
          ),
        ),
        placeId: 999,
      );

      await controller.loadPlace();

      expect(controller.errorMessage, '없는 장소이거나 삭제된 장소입니다.');
    });

    test('저장하면 등록이 아니라 수정을 부른다', () async {
      final repository = _StubPlacesRepository();
      final controller = PlaceFormController(
        repository: repository,
        placeId: 7,
      );
      controller.updateValues(const PlaceFormValues(name: '바뀐 이름'));

      final id = await controller.submit();

      expect(id, 7);
      expect(repository.lastCreated, isNull);
      expect(repository.lastUpdated?.id, 7);
      expect(repository.lastUpdated?.body['name'], '바뀐 이름');
    });
  });

  group('내가 등록한 장소', () {
    test('목록을 불러온다', () async {
      final repository = _StubPlacesRepository();
      final controller = MyPlacesController(repository);

      await controller.load();

      expect(controller.places, hasLength(2));
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('실패하면 문구를 남기고 목록을 비운다', () async {
      final controller = MyPlacesController(
        _StubPlacesRepository(
          listError: const ApiException(statusCode: 500, message: '서버 오류입니다.'),
        ),
      );

      await controller.load();

      expect(controller.places, isEmpty);
      expect(controller.errorMessage, '서버 오류입니다.');
    });

    test('삭제하면 목록에서 지우고 다시 부르지 않는다', () async {
      final repository = _StubPlacesRepository();
      final controller = MyPlacesController(repository);
      await controller.load();

      final ok = await controller.delete(1);

      expect(ok, isTrue);
      expect(repository.lastDeletedId, 1);
      expect(controller.places.map((place) => place.id), [2]);
      // 결과가 명확해서 목록을 다시 받지 않습니다.
      expect(repository.myPlacesCallCount, 1);
    });

    test('삭제 실패는 목록을 그대로 두고 알린다', () async {
      // 남의 장소를 지우려 하면 서버가 403을 줍니다.
      final controller = MyPlacesController(
        _StubPlacesRepository(
          writeError: const ApiException(
            statusCode: 403,
            message: '직접 등록한 장소만 변경할 수 있습니다.',
          ),
        ),
      );
      await controller.load();

      final ok = await controller.delete(1);

      expect(ok, isFalse);
      expect(controller.places, hasLength(2));
      expect(controller.errorMessage, '직접 등록한 장소만 변경할 수 있습니다.');
      expect(controller.deletingId, isNull);
    });
  });
}
