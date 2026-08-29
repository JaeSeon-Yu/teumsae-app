import '../places/place_detail.dart';

/// 서버 `UserReviewResponse`. 공개 프로필에 보이는 후기 한 건입니다.
///
/// 장소 상세의 후기(`PlaceReview`)와 달리 작성자가 아니라 장소를 함께 들고 있습니다.
class UserReview {
  const UserReview({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final int id;
  final int placeId;
  final String placeName;
  final int rating;
  final String comment;
  final String createdAt;

  factory UserReview.fromJson(Map<String, dynamic> json) {
    return UserReview(
      id: (json['id'] as num).toInt(),
      placeId: (json['placeId'] as num?)?.toInt() ?? 0,
      placeName: json['placeName'] as String? ?? '',
      rating: ((json['rating'] as num?)?.round() ?? 0).clamp(0, 5),
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  /// 목록에 보여 줄 날짜. 후기 목록과 같은 규칙입니다. (2026.08.28)
  String get dateLabel {
    final parsed = DateTime.tryParse(createdAt);
    if (parsed == null) {
      return createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;
    }
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}.$month.$day';
  }
}

/// 서버 `UserProfileResponse`. 로그인 없이도 볼 수 있습니다.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.createdAt,
    required this.registeredPlacesCount,
    required this.reviewsCount,
    required this.registeredPlaces,
    required this.reviews,
  });

  final int id;
  final String username;
  final String createdAt;
  final int registeredPlacesCount;
  final int reviewsCount;
  final List<PlaceDetail> registeredPlaces;
  final List<UserReview> reviews;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      registeredPlacesCount:
          (json['registeredPlacesCount'] as num?)?.toInt() ?? 0,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
      registeredPlaces: _list(
        json['registeredPlaces'],
        PlaceDetail.fromJson,
      ),
      reviews: _list(json['reviews'], UserReview.fromJson),
    );
  }

  /// 가입일. 웹은 `toLocaleDateString("ko-KR")`로 보여 줍니다.
  String get joinedLabel {
    final parsed = DateTime.tryParse(createdAt);
    if (parsed == null) {
      return '';
    }
    return '${parsed.year}년 ${parsed.month}월 ${parsed.day}일 가입';
  }

  static List<T> _list<T>(
    Object? value,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(parse)
          .toList(growable: false);
    }
    return const [];
  }
}

/// 신고 대상. 서버 `ReportTargetType`과 같습니다.
enum ReportTarget {
  place('PLACE', '장소'),
  review('REVIEW', '후기'),
  user('USER', '사용자'),
  ;

  const ReportTarget(this.value, this.label);

  final String value;
  final String label;
}

/// 신고 입력 규칙. 서버 `Report.reason`이 100자 제한입니다.
abstract final class ReportValidators {
  static const maxReasonLength = 100;

  static String? validateReason(String? value) {
    final reason = value?.trim() ?? '';

    if (reason.isEmpty) {
      return '신고 사유를 입력해 주세요.';
    }
    if (reason.length > maxReasonLength) {
      return '신고 사유는 $maxReasonLength자 이하로 입력해 주세요.';
    }
    return null;
  }
}
