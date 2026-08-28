import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/features/places/place_review.dart';

void main() {
  group('파싱', () {
    test('서버 응답을 그대로 옮긴다', () {
      final review = PlaceReview.fromJson(const {
        'id': 5,
        'userId': 7,
        'username': 'jason',
        'rating': 4,
        'comment': '조용해서 좋았어요',
        'createdAt': '2026-08-28T23:04:11.123',
      });

      expect(review.id, 5);
      expect(review.userId, 7);
      expect(review.username, 'jason');
      expect(review.rating, 4);
      expect(review.comment, '조용해서 좋았어요');
    });

    test('날짜는 연월일만 보여 준다', () {
      final review = PlaceReview.fromJson(const {
        'id': 1,
        'createdAt': '2026-08-28T23:04:11.123',
      });

      expect(review.dateLabel, '2026.08.28');
    });

    test('날짜 형식이 바뀌어도 앞부분을 보여 준다', () {
      // 빈칸을 두는 대신 원문을 잘라 씁니다.
      final review = PlaceReview.fromJson(const {
        'id': 1,
        'createdAt': '28/08/2026 23:04',
      });

      expect(review.dateLabel, '28/08/2026');
    });
  });

  group('검증', () {
    // 서버 `CreateReviewRequest`의 제약과 같은 값이어야 합니다.
    test('평점은 1~5만 통과한다', () {
      expect(ReviewValidators.validateRating(1), isNull);
      expect(ReviewValidators.validateRating(5), isNull);
      expect(ReviewValidators.validateRating(0), isNotNull);
      expect(ReviewValidators.validateRating(6), isNotNull);
      expect(ReviewValidators.validateRating(null), isNotNull);
    });

    test('빈 후기와 공백만 있는 후기를 막는다', () {
      expect(ReviewValidators.validateComment(''), '후기 내용을 입력해 주세요.');
      expect(ReviewValidators.validateComment('   '), '후기 내용을 입력해 주세요.');
      expect(ReviewValidators.validateComment(null), '후기 내용을 입력해 주세요.');
    });

    test('1000자까지 통과하고 넘으면 막는다', () {
      expect(ReviewValidators.validateComment('가' * 1000), isNull);
      expect(
        ReviewValidators.validateComment('가' * 1001),
        '후기는 1000자 이하로 입력해 주세요.',
      );
    });

    test('서버 제약과 같은 상수를 쓴다', () {
      expect(ReviewValidators.minRating, 1);
      expect(ReviewValidators.maxRating, 5);
      expect(ReviewValidators.maxCommentLength, 1000);
    });
  });
}
