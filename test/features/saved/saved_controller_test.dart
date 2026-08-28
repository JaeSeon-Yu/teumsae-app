import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/core/network/api_client.dart';
import 'package:teumsae_app/src/core/network/api_exception.dart';
import 'package:teumsae_app/src/core/network/auth_tokens.dart';
import 'package:teumsae_app/src/core/storage/token_store.dart';
import 'package:teumsae_app/src/features/auth/auth_controller.dart';
import 'package:teumsae_app/src/features/auth/auth_repository.dart';
import 'package:teumsae_app/src/features/auth/auth_user.dart';
import 'package:teumsae_app/src/features/saved/saved_controller.dart';
import 'package:teumsae_app/src/features/saved/saved_place.dart';
import 'package:teumsae_app/src/features/saved/saved_repository.dart';

SavedPlace _place(int id) => SavedPlace.fromJson({
      'id': id,
      'name': '성북구립도서관 $id',
      'typeLabel': '도서관',
      'address': '서울 성북구 화랑로',
      'priceLabel': '무료',
      'indoor': true,
      'stayMinutesMin': 30,
      'stayMinutesMax': 180,
      'tags': ['조용함'],
      'savedAt': '2026-08-28T10:00:00',
    });

class _StubSavedRepository extends SavedRepository {
  _StubSavedRepository({this.error, List<int>? initialIds})
      : _ids = {...?initialIds},
        super(ApiClient(tokenStore: InMemoryTokenStore()));

  final Object? error;
  final Set<int> _ids;

  int listCount = 0;
  final saved = <int>[];
  final unsaved = <int>[];

  @override
  Future<List<SavedPlace>> list() async {
    listCount++;
    if (error != null) throw error!;
    return _ids.map(_place).toList(growable: false);
  }

  @override
  Future<void> save(int placeId) async {
    if (error != null) throw error!;
    saved.add(placeId);
    _ids.add(placeId);
  }

  @override
  Future<void> unsave(int placeId) async {
    if (error != null) throw error!;
    unsaved.add(placeId);
    _ids.remove(placeId);
  }
}

class _StubAuthRepository extends AuthRepository {
  _StubAuthRepository()
      : super(
          apiClient: ApiClient(tokenStore: InMemoryTokenStore()),
          tokenStore: InMemoryTokenStore(),
        );

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async =>
      AuthSession(
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

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<void> logout() async {}
}

/// 로그인 상태를 만들고 저장 컨트롤러를 붙입니다.
Future<(SavedController, AuthController)> _signedIn(
  _StubSavedRepository repository,
) async {
  final auth = AuthController(_StubAuthRepository());
  await auth.login(username: 'teumsae_user', password: 'password');

  final controller = SavedController(repository: repository, auth: auth);
  controller.onInit();
  addTearDown(controller.onClose);
  // onInit이 시작한 첫 조회가 끝날 때까지 기다립니다.
  await Future<void>.delayed(Duration.zero);

  return (controller, auth);
}

void main() {
  test('로그인 상태로 시작하면 저장 목록을 불러온다', () async {
    final repository = _StubSavedRepository(initialIds: [1, 2]);
    final (controller, _) = await _signedIn(repository);

    expect(repository.listCount, 1);
    expect(controller.count, 2);
    expect(controller.isSaved(1), isTrue);
    expect(controller.isSaved(3), isFalse);
    expect(controller.errorMessage, isNull);
  });

  test('로그인하면 목록을 불러온다', () async {
    final repository = _StubSavedRepository(initialIds: [7]);
    final auth = AuthController(_StubAuthRepository());
    final controller = SavedController(repository: repository, auth: auth);
    controller.onInit();
    addTearDown(controller.onClose);

    // 로그아웃 상태에서는 서버를 호출하지 않습니다.
    expect(repository.listCount, 0);

    await auth.login(username: 'teumsae_user', password: 'password');
    await Future<void>.delayed(Duration.zero);

    expect(repository.listCount, 1);
    expect(controller.isSaved(7), isTrue);
  });

  test('로그아웃하면 저장 상태를 비운다', () async {
    final repository = _StubSavedRepository(initialIds: [1]);
    final (controller, auth) = await _signedIn(repository);
    expect(controller.isSaved(1), isTrue);

    await auth.logout();
    await Future<void>.delayed(Duration.zero);

    expect(controller.count, 0);
    expect(controller.isSaved(1), isFalse);
  });

  test('세션이 만료되어도 저장 상태를 비운다', () async {
    final repository = _StubSavedRepository(initialIds: [1]);
    final (controller, auth) = await _signedIn(repository);

    auth.handleSessionExpired();
    await Future<void>.delayed(Duration.zero);

    expect(controller.count, 0);
  });

  group('toggle', () {
    test('저장하면 서버 목록을 다시 불러온다', () async {
      // 저장 시각·표시 정보는 서버가 채우므로 로컬에서 만들지 않습니다.
      final repository = _StubSavedRepository();
      final (controller, _) = await _signedIn(repository);

      final result = await controller.toggle(5);

      expect(result, isTrue);
      expect(repository.saved, [5]);
      expect(repository.listCount, 2);
      expect(controller.isSaved(5), isTrue);
      expect(controller.count, 1);
    });

    test('저장을 취소하면 목록에서 바로 빠진다', () async {
      final repository = _StubSavedRepository(initialIds: [1, 2]);
      final (controller, _) = await _signedIn(repository);

      final result = await controller.toggle(1);

      expect(result, isTrue);
      expect(repository.unsaved, [1]);
      expect(controller.isSaved(1), isFalse);
      expect(controller.count, 1);
      // 취소는 재조회 없이 로컬에서 지웁니다.
      expect(repository.listCount, 1);
    });

    test('로그인하지 않았으면 아무것도 하지 않는다', () async {
      final repository = _StubSavedRepository();
      final auth = AuthController(_StubAuthRepository());
      final controller = SavedController(repository: repository, auth: auth);

      expect(await controller.toggle(1), isFalse);
      expect(repository.saved, isEmpty);
    });

    test('실패하면 서버 메시지를 노출하고 상태를 되돌린다', () async {
      final repository = _StubSavedRepository(initialIds: [1]);
      final (controller, _) = await _signedIn(repository);

      final failing = SavedController(
        repository: _StubSavedRepository(
          error: const ApiException(statusCode: 500, message: '서버 오류입니다.'),
        ),
        auth: (await _signedIn(_StubSavedRepository())).$2,
      );

      expect(await failing.toggle(9), isFalse);
      expect(failing.errorMessage, '서버 오류입니다.');
      expect(failing.isSaved(9), isFalse);
      expect(controller.isSaved(1), isTrue);
    });
  });

  test('목록 조회가 실패하면 안내 문구를 남긴다', () async {
    final repository = _StubSavedRepository(
      error: const ApiException(statusCode: 500, message: '서버 오류입니다.'),
    );
    final (controller, _) = await _signedIn(repository);

    expect(controller.errorMessage, '서버 오류입니다.');
    expect(controller.count, 0);

    controller.clearError();
    expect(controller.errorMessage, isNull);
  });
}
