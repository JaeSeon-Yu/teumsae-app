import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/core/network/api_client.dart';
import 'package:teumsae_app/src/core/network/api_exception.dart';
import 'package:teumsae_app/src/core/storage/token_store.dart';
import 'package:teumsae_app/src/features/auth/auth_controller.dart';
import 'package:teumsae_app/src/features/auth/auth_repository.dart';
import 'package:teumsae_app/src/features/users/block_controller.dart';
import 'package:teumsae_app/src/features/users/user_profile.dart';
import 'package:teumsae_app/src/features/users/users_repository.dart';

class _StubAuthRepository extends AuthRepository {
  _StubAuthRepository()
      : super(
          apiClient: ApiClient(tokenStore: InMemoryTokenStore()),
          tokenStore: InMemoryTokenStore(),
        );

  @override
  Future<AuthSession?> restoreSession() async => null;
}

class _StubUsersRepository extends UsersRepository {
  _StubUsersRepository({Set<int>? blocked, this.error})
      : blocked = {...?blocked},
        super(ApiClient(tokenStore: InMemoryTokenStore()));

  final Set<int> blocked;
  final Object? error;

  ({String target, int id, String reason})? lastReport;

  @override
  Future<Set<int>> blockedUserIds() async {
    if (error != null) throw error!;
    return {...blocked};
  }

  @override
  Future<void> block(int userId) async {
    if (error != null) throw error!;
    blocked.add(userId);
  }

  @override
  Future<void> unblock(int userId) async {
    if (error != null) throw error!;
    blocked.remove(userId);
  }

  @override
  Future<void> report({
    required ReportTarget target,
    required int targetId,
    required String reason,
    String? details,
  }) async {
    lastReport = (target: target.value, id: targetId, reason: reason);
    if (error != null) throw error!;
  }
}

BlockController _controller(_StubUsersRepository repository) {
  return BlockController(
    repository: repository,
    auth: AuthController(_StubAuthRepository()),
  );
}

void main() {
  group('프로필 파싱', () {
    test('서버 응답을 그대로 옮긴다', () {
      final profile = UserProfile.fromJson(const {
        'id': 7,
        'username': 'jason',
        'createdAt': '2026-01-02T10:00:00.000',
        'registeredPlacesCount': 2,
        'reviewsCount': 3,
        'registeredPlaces': [
          {'id': 1, 'name': '성북구립도서관'},
        ],
        'reviews': [
          {
            'id': 5,
            'placeId': 1,
            'placeName': '성북구립도서관',
            'rating': 4,
            'comment': '조용해요',
            'createdAt': '2026-08-28T23:04:11.123',
          },
        ],
      });

      expect(profile.id, 7);
      expect(profile.username, 'jason');
      expect(profile.registeredPlacesCount, 2);
      expect(profile.reviewsCount, 3);
      expect(profile.registeredPlaces.single.name, '성북구립도서관');
      expect(profile.reviews.single.placeName, '성북구립도서관');
      expect(profile.reviews.single.dateLabel, '2026.08.28');
      expect(profile.joinedLabel, '2026년 1월 2일 가입');
    });

    test('목록이 없어도 빈 값으로 둔다', () {
      final profile = UserProfile.fromJson(const {'id': 1, 'username': 'a'});

      expect(profile.registeredPlaces, isEmpty);
      expect(profile.reviews, isEmpty);
      expect(profile.joinedLabel, '');
    });
  });

  group('신고 사유 검증', () {
    test('빈 사유를 막는다', () {
      expect(ReportValidators.validateReason(''), '신고 사유를 입력해 주세요.');
      expect(ReportValidators.validateReason('   '), '신고 사유를 입력해 주세요.');
    });

    test('서버 제약과 같은 100자까지 받는다', () {
      // 서버 `Report.reason`이 length = 100입니다.
      expect(ReportValidators.maxReasonLength, 100);
      expect(ReportValidators.validateReason('가' * 100), isNull);
      expect(
        ReportValidators.validateReason('가' * 101),
        '신고 사유는 100자 이하로 입력해 주세요.',
      );
    });
  });

  group('차단', () {
    test('차단 목록을 불러온다', () async {
      final controller = _controller(_StubUsersRepository(blocked: {3, 9}));

      await controller.load();

      expect(controller.isBlocked(3), isTrue);
      expect(controller.isBlocked(9), isTrue);
      expect(controller.isBlocked(1), isFalse);
    });

    test('목록을 못 받아도 비운 채로 넘어간다', () async {
      // 차단 목록이 없어도 나머지 화면은 그대로 써야 합니다.
      final controller = _controller(
        _StubUsersRepository(error: StateError('boom')),
      );

      await controller.load();

      expect(controller.isBlocked(1), isFalse);
    });

    test('차단하면 상태가 바뀐다', () async {
      final repository = _StubUsersRepository();
      final controller = _controller(repository);

      final ok = await controller.block(5);

      expect(ok, isTrue);
      expect(controller.isBlocked(5), isTrue);
      expect(repository.blocked, contains(5));
    });

    test('차단을 해제하면 상태가 돌아온다', () async {
      final repository = _StubUsersRepository(blocked: {5});
      final controller = _controller(repository);
      await controller.load();

      final ok = await controller.unblock(5);

      expect(ok, isTrue);
      expect(controller.isBlocked(5), isFalse);
      expect(repository.blocked, isEmpty);
    });

    test('실패하면 상태를 바꾸지 않고 알린다', () async {
      // 자기 자신을 차단하면 서버가 막습니다.
      final controller = _controller(
        _StubUsersRepository(
          error: const ApiException(
            statusCode: 400,
            message: 'You cannot block yourself.',
          ),
        ),
      );

      final ok = await controller.block(1);

      expect(ok, isFalse);
      expect(controller.isBlocked(1), isFalse);
      expect(controller.errorMessage, 'You cannot block yourself.');
    });
  });

  group('신고', () {
    test('사유와 대상을 그대로 보낸다', () async {
      final repository = _StubUsersRepository();
      final controller = _controller(repository);

      final ok = await controller.report(
        target: ReportTarget.review,
        targetId: 12,
        reason: '  욕설  ',
      );

      expect(ok, isTrue);
      expect(repository.lastReport?.target, 'REVIEW');
      expect(repository.lastReport?.id, 12);
      // 앞뒤 공백은 리포지토리에서 다듬습니다.
      expect(repository.lastReport?.reason, '  욕설  ');
    });

    test('빈 사유는 서버를 부르지 않고 막는다', () async {
      final repository = _StubUsersRepository();
      final controller = _controller(repository);

      final ok = await controller.report(
        target: ReportTarget.user,
        targetId: 1,
        reason: '   ',
      );

      expect(ok, isFalse);
      expect(repository.lastReport, isNull);
      expect(controller.errorMessage, '신고 사유를 입력해 주세요.');
    });

    test('실패는 서버 메시지를 그대로 노출한다', () async {
      final controller = _controller(
        _StubUsersRepository(
          error: const ApiException(statusCode: 500, message: '서버 오류입니다.'),
        ),
      );

      final ok = await controller.report(
        target: ReportTarget.place,
        targetId: 1,
        reason: '스팸',
      );

      expect(ok, isFalse);
      expect(controller.errorMessage, '서버 오류입니다.');
    });
  });
}
