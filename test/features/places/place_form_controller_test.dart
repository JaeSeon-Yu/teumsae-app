import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/core/network/api_client.dart';
import 'package:teumsae_app/src/core/network/api_exception.dart';
import 'package:teumsae_app/src/core/network/auth_tokens.dart';
import 'package:teumsae_app/src/core/storage/token_store.dart';
import 'package:teumsae_app/src/features/auth/auth_controller.dart';
import 'package:teumsae_app/src/features/auth/auth_repository.dart';
import 'package:teumsae_app/src/features/auth/auth_user.dart';
import 'package:teumsae_app/src/features/places/my_places_controller.dart';
import 'package:teumsae_app/src/features/places/place_detail.dart';
import 'package:teumsae_app/src/features/places/place_form.dart';
import 'package:teumsae_app/src/features/places/place_form_controller.dart';
import 'package:teumsae_app/src/features/places/places_repository.dart';

/// 대역이 돌려주는 장소를 등록한 사용자의 고유 번호.
const _ownerId = 1;

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
      // 수정할 수 있는 장소는 사용자가 등록한 것뿐입니다.
      'userCreated': true,
      'createdByUserId': _ownerId,
      ...overrides,
    });

class _StubAuthRepository extends AuthRepository {
  _StubAuthRepository({this.user})
      : super(
          apiClient: ApiClient(tokenStore: InMemoryTokenStore()),
          tokenStore: InMemoryTokenStore(),
        );

  /// 복구할 세션의 사용자. `null`이면 비로그인 상태로 둡니다.
  final AuthUser? user;

  @override
  Future<AuthSession?> restoreSession() async {
    final signedIn = user;
    if (signedIn == null) {
      return null;
    }

    return AuthSession(
      user: signedIn,
      tokens: AuthTokens(
        tokenType: 'Bearer',
        accessToken: 'access',
        accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
        refreshToken: 'refresh',
      ),
    );
  }
}

/// 등록 폼은 로그인 상태를 보지 않으므로 비로그인 컨트롤러로 충분합니다.
AuthController _signedOut() => AuthController(_StubAuthRepository());

/// 고유 번호가 [userId]인 사용자로 로그인한 컨트롤러.
Future<AuthController> _signedIn(int userId) async {
  final auth = AuthController(
    _StubAuthRepository(
      user: AuthUser(
        id: userId,
        username: 'user$userId',
        nickname: '사용자$userId',
        role: 'USER',
        provider: 'LOCAL',
      ),
    ),
  );
  await auth.restoreSession();
  return auth;
}

class _StubPlacesRepository extends PlacesRepository {
  _StubPlacesRepository({
    this.writeError,
    this.listError,
    this.detailOverrides = const {},
  }) : super(ApiClient(tokenStore: InMemoryTokenStore()));

  /// 등록·수정·삭제에서 던질 예외.
  final Object? writeError;

  /// 목록·상세 조회에서 던질 예외.
  final Object? listError;

  /// 상세 조회가 돌려줄 장소에서 바꿀 필드.
  final Map<String, dynamic> detailOverrides;

  Map<String, dynamic>? lastCreated;
  ({int id, Map<String, dynamic> body})? lastUpdated;
  int? lastDeletedId;
  int tagCallCount = 0;
  int myPlacesCallCount = 0;
  String? stubbedAddress = '서울 성북구 화랑로 123';

  @override
  Future<PlaceDetail> getPlace(int id) async {
    if (listError != null) throw listError!;
    return _detail(id: id, overrides: detailOverrides);
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
      final controller =
          PlaceFormController(repository: repository, auth: _signedOut());

      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(repository.tagCallCount, 1);
      expect(controller.tagOptions, hasLength(2));
      expect(controller.isEditing, isFalse);
      expect(controller.title, '장소 등록');
    });

    test('검증에 걸리면 서버를 부르지 않는다', () async {
      final repository = _StubPlacesRepository();
      final controller =
          PlaceFormController(repository: repository, auth: _signedOut());

      final id = await controller.submit();

      expect(id, isNull);
      expect(repository.lastCreated, isNull);
      expect(controller.errorMessage, '장소 이름을 입력해 주세요.');
    });

    test('등록에 성공하면 새 장소 id를 준다', () async {
      final repository = _StubPlacesRepository();
      final controller =
          PlaceFormController(repository: repository, auth: _signedOut());
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
        auth: _signedOut(),
      );
      controller.updateValues(const PlaceFormValues(name: '틈새 쉼터'));

      final id = await controller.submit();

      expect(id, isNull);
      expect(controller.errorMessage, '이미 등록된 장소입니다.');
    });

    test('태그를 켜면 편의시설 플래그도 함께 움직인다', () {
      final controller = PlaceFormController(
        repository: _StubPlacesRepository(),
        auth: _signedOut(),
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
        auth: _signedOut(),
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
        auth: _signedOut(),
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
        auth: _signedOut(),
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
        auth: await _signedIn(_ownerId),
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
        auth: await _signedIn(_ownerId),
        placeId: 999,
      );

      await controller.loadPlace();

      expect(controller.errorMessage, '없는 장소이거나 삭제된 장소입니다.');
    });

    test('저장하면 등록이 아니라 수정을 부른다', () async {
      final repository = _StubPlacesRepository();
      final controller = PlaceFormController(
        repository: repository,
        auth: await _signedIn(_ownerId),
        placeId: 7,
      );
      controller.updateValues(const PlaceFormValues(name: '바뀐 이름'));

      final id = await controller.submit();

      expect(id, 7);
      expect(repository.lastCreated, isNull);
      expect(repository.lastUpdated?.id, 7);
      expect(repository.lastUpdated?.body['name'], '바뀐 이름');
    });

    test('남이 등록한 장소는 폼을 잠근다', () async {
      final repository = _StubPlacesRepository();
      final controller = PlaceFormController(
        repository: repository,
        // 작성자 고유 번호가 다른 사용자로 들어옵니다.
        auth: await _signedIn(_ownerId + 1),
        placeId: 7,
      );

      await controller.loadPlace();

      expect(controller.isEditable, isFalse);
      expect(controller.errorMessage, '직접 등록한 장소만 수정할 수 있습니다.');
      // 값을 채우지 않아 남의 장소 정보가 폼에 노출되지 않습니다.
      expect(controller.values.name, isEmpty);

      controller.updateValues(const PlaceFormValues(name: '바꿔치기'));
      expect(await controller.submit(), isNull);
      expect(repository.lastUpdated, isNull);
    });

    test('공공데이터로 들여온 장소도 잠근다', () async {
      final repository = _StubPlacesRepository(
        // 사용자가 등록하지 않은 장소는 작성자가 없습니다.
        detailOverrides: const {'userCreated': false, 'createdByUserId': null},
      );
      final controller = PlaceFormController(
        repository: repository,
        auth: await _signedIn(_ownerId),
        placeId: 7,
      );

      await controller.loadPlace();

      expect(controller.isEditable, isFalse);
      expect(controller.errorMessage, '직접 등록한 장소만 수정할 수 있습니다.');
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
