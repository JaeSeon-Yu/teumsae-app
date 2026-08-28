/// 서버 `PlaceReviewResponse`.
///
/// 후기 목록에는 따로 조회 엔드포인트가 없습니다. `GET /api/places/{id}`가
/// 상세 응답 안에 함께 내려줍니다. (웹도 같은 값을 씁니다)
class PlaceReview {
  const PlaceReview({
    required this.id,
    required this.userId,
    required this.username,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final int id;

  /// 작성자 id. 내 후기인지 판단해 삭제 버튼을 보일지 정합니다.
  final int userId;

  final String username;

  /// 1~5.
  final int rating;

  final String comment;

  /// 서버가 `LocalDateTime.toString()`으로 보냅니다. (예: `2026-08-28T23:04:11.123`)
  /// 파싱에 실패해도 화면이 깨지지 않게 원문을 함께 둡니다.
  final String createdAt;

  factory PlaceReview.fromJson(Map<String, dynamic> json) {
    return PlaceReview(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      rating: ((json['rating'] as num?)?.round() ?? 0).clamp(0, 5),
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  /// 목록에 보여 줄 날짜. 웹은 `createdAt.slice(0, 10)`으로 날짜만 씁니다.
  /// 앱도 같은 정보를 보여 주되 점으로 구분합니다. (2026.08.28)
  String get dateLabel {
    final parsed = DateTime.tryParse(createdAt);
    if (parsed == null) {
      // 형식이 바뀌어도 빈칸 대신 원문 앞부분을 보여 줍니다.
      return createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;
    }

    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}.$month.$day';
  }
}

/// 후기 입력 검증.
///
/// 서버 `CreateReviewRequest`의 제약과 반드시 같은 값을 씁니다.
/// 한쪽만 바꾸면 앱에서는 통과했는데 서버가 400을 주는 상황이 생깁니다.
abstract final class ReviewValidators {
  /// 서버: `@Min(1)` / `@Max(5)`
  static const minRating = 1;
  static const maxRating = 5;

  /// 서버: `@Size(max = 1000)` + `@NotBlank`
  static const maxCommentLength = 1000;

  /// 웹 폼의 기본 선택값과 같습니다.
  static const defaultRating = 5;

  /// 통과하면 `null`, 아니면 화면에 그대로 띄울 한글 문구를 반환합니다.
  static String? validateRating(int? value) {
    if (value == null || value < minRating || value > maxRating) {
      return '평점을 $minRating~$maxRating점 사이로 선택해 주세요.';
    }
    return null;
  }

  static String? validateComment(String? value) {
    final comment = value?.trim() ?? '';

    if (comment.isEmpty) {
      return '후기 내용을 입력해 주세요.';
    }
    if (comment.length > maxCommentLength) {
      return '후기는 $maxCommentLength자 이하로 입력해 주세요.';
    }
    return null;
  }
}
