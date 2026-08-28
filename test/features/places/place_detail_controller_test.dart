import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/core/network/api_client.dart';
import 'package:teumsae_app/src/core/network/api_exception.dart';
import 'package:teumsae_app/src/core/storage/token_store.dart';
import 'package:teumsae_app/src/features/places/place_detail.dart';
import 'package:teumsae_app/src/features/places/place_detail_controller.dart';
import 'package:teumsae_app/src/features/places/place_review.dart';
import 'package:teumsae_app/src/features/places/places_repository.dart';

PlaceDetail _place(int id, {List<Map<String, dynamic>> reviews = const []}) =>
    PlaceDetail.fromJson({
      'id': id,
      'name': '성북구립도서관',
      'typeLabel': '도서관',
      'openStatusLabel': '영업중',
      'reviewCount': reviews.length,
      'reviews': reviews,
    });

class _StubPlacesRepository extends PlacesRepository {
  _StubPlacesRepository({this.error, this.reviewError})
      : super(ApiClient(tokenStore: InMemoryTokenStore()));

  final Object? error;

  /// 후기 작성·삭제에서만 던질 예외. 조회는 성공시켜 두고 실패를 확인합니다.
  final Object? reviewError;

  int? lastRequestedId;
  int callCount = 0;

  /// 서버에 실제로 전달된 후기 내용. 검증이 막았는지 확인하는 데 씁니다.
  ({int placeId, int rating, String comment})? lastCreated;
  ({int placeId, int reviewId})? lastDeleted;

  /// 작성 후 조회에서 돌려줄 후기 목록.
  List<Map<String, dynamic>> stubbedReviews = const [];

  @override
  Future<PlaceDetail> getPlace(int id) async {
    lastRequestedId = id;
    callCount++;
    if (error != null) throw error!;
    return _place(id, reviews: stubbedReviews);
  }

  @override
  Future<PlaceReview> createReview({
    required int placeId,
    required int rating,
    required String comment,
  }) async {
    lastCreated = (placeId: placeId, rating: rating, comment: comment);
    if (reviewError != null) throw reviewError!;
    return PlaceReview.fromJson({
      'id': 1,
      'userId': 7,
      'username': 'jason',
      'rating': rating,
      'comment': comment,
      'createdAt': '2026-08-28T23:04:11.123',
    });
  }

  @override
  Future<void> deleteReview({
    required int placeId,
    required int reviewId,
  }) async {
    lastDeleted = (placeId: placeId, reviewId: reviewId);
    if (reviewError != null) throw reviewError!;
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

  group('후기', () {
    test('상세 응답의 후기 목록을 그대로 노출한다', () async {
      final repository = _StubPlacesRepository()
        ..stubbedReviews = const [
          {
            'id': 5,
            'userId': 7,
            'username': 'jason',
            'rating': 4,
            'comment': '조용해서 좋았어요',
            'createdAt': '2026-08-28T23:04:11.123',
          },
        ];
      final controller = PlaceDetailController(repository: repository, id: 1);

      await controller.load();

      expect(controller.reviews, hasLength(1));
      expect(controller.reviews.first.comment, '조용해서 좋았어요');
      expect(controller.reviews.first.dateLabel, '2026.08.28');
    });

    test('후기를 등록하면 상세를 다시 불러온다', () async {
      // 평균 별점과 후기 수는 서버가 계산하므로 로컬에서 더하지 않습니다.
      final repository = _StubPlacesRepository();
      final controller = PlaceDetailController(repository: repository, id: 2);
      await controller.load();

      final ok = await controller.submitReview('  조용해서 좋았어요  ');

      expect(ok, isTrue);
      expect(repository.lastCreated?.placeId, 2);
      expect(repository.lastCreated?.rating, 5);
      // 앞뒤 공백은 서버에 보내기 전에 다듬습니다.
      expect(repository.lastCreated?.comment, '조용해서 좋았어요');
      expect(repository.callCount, 2);
      expect(controller.reviewError, isNull);
    });

    test('등록 후 별점은 기본값으로 돌아간다', () async {
      final controller = PlaceDetailController(
        repository: _StubPlacesRepository(),
        id: 1,
      );
      controller.changeRating(2);

      await controller.submitReview('좋아요');

      expect(controller.rating, 5);
    });

    test('빈 후기는 서버를 부르지 않고 막는다', () async {
      final repository = _StubPlacesRepository();
      final controller = PlaceDetailController(repository: repository, id: 1);
      await controller.load();

      final ok = await controller.submitReview('   ');

      expect(ok, isFalse);
      expect(repository.lastCreated, isNull);
      expect(controller.reviewError, '후기 내용을 입력해 주세요.');
      expect(repository.callCount, 1);
    });

    test('1000자를 넘는 후기도 서버를 부르지 않고 막는다', () async {
      final repository = _StubPlacesRepository();
      final controller = PlaceDetailController(repository: repository, id: 1);

      final ok = await controller.submitReview('가' * 1001);

      expect(ok, isFalse);
      expect(repository.lastCreated, isNull);
      expect(controller.reviewError, '후기는 1000자 이하로 입력해 주세요.');
    });

    test('별점은 1~5 밖의 값을 받지 않는다', () {
      final controller = PlaceDetailController(
        repository: _StubPlacesRepository(),
        id: 1,
      );

      controller.changeRating(0);
      expect(controller.rating, 5);

      controller.changeRating(6);
      expect(controller.rating, 5);

      controller.changeRating(3);
      expect(controller.rating, 3);
    });

    test('등록 실패는 서버 메시지를 그대로 노출한다', () async {
      final controller = PlaceDetailController(
        repository: _StubPlacesRepository(
          reviewError: const ApiException(
            statusCode: 400,
            message: '댓글은 1000자 이내여야 합니다.',
          ),
        ),
        id: 1,
      );

      final ok = await controller.submitReview('좋아요');

      expect(ok, isFalse);
      expect(controller.reviewError, '댓글은 1000자 이내여야 합니다.');
    });

    test('후기를 지우면 상세를 다시 불러온다', () async {
      final repository = _StubPlacesRepository();
      final controller = PlaceDetailController(repository: repository, id: 4);
      await controller.load();

      final ok = await controller.deleteReview(9);

      expect(ok, isTrue);
      expect(repository.lastDeleted?.placeId, 4);
      expect(repository.lastDeleted?.reviewId, 9);
      expect(repository.callCount, 2);
    });

    test('삭제 실패는 서버 메시지를 그대로 노출한다', () async {
      // 남의 후기를 지우려 하면 서버가 403을 줍니다.
      final controller = PlaceDetailController(
        repository: _StubPlacesRepository(
          reviewError: const ApiException(
            statusCode: 403,
            message: '본인의 리뷰만 삭제할 수 있습니다.',
          ),
        ),
        id: 1,
      );

      final ok = await controller.deleteReview(9);

      expect(ok, isFalse);
      expect(controller.reviewError, '본인의 리뷰만 삭제할 수 있습니다.');
      expect(controller.deletingReviewId, isNull);
    });

    test('실패 문구는 화면에서 보여 준 뒤 지울 수 있다', () async {
      final controller = PlaceDetailController(
        repository: _StubPlacesRepository(),
        id: 1,
      );
      await controller.submitReview('');

      controller.clearReviewError();

      expect(controller.reviewError, isNull);
    });
  });
}
