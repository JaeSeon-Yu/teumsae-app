import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/features/places/place_detail.dart';

/// 서버 `PlaceDetailResponse`의 전형적인 응답.
Map<String, dynamic> _json() => {
      'id': 12,
      'name': '성북구립도서관',
      'type': 'LIBRARY',
      'typeLabel': '도서관',
      'address': '서울 성북구 화랑로',
      'lat': 37.5921,
      'lng': 127.0161,
      'priceLevel': 'FREE',
      'priceLabel': '무료',
      'estimatedCostMin': 0,
      'estimatedCostMax': 0,
      'indoor': true,
      'outdoor': false,
      'stayMinutesMin': 30,
      'stayMinutesMax': 180,
      'openStatus': 'OPEN',
      'openStatusLabel': '영업중',
      'scores': {
        'seating': 5,
        'wifi': 4,
        'toilet': 5,
        'charging': 3,
        'quiet': 5,
        'laptop': 4,
      },
      'weatherScores': {'rain': 5, 'heat': 4, 'cold': 5, 'sunny': 2},
      'openingHoursText': '평일 09:00-18:00',
      'source': '공공데이터포털',
      'sourceUrl': 'https://www.data.go.kr',
      'description': '조용한 열람실이 있습니다.',
      'warnings': ['음식물 반입 금지'],
      'tags': ['조용함', '와이파이'],
      'themes': ['REST'],
      'saved': true,
      'userCreated': false,
      'createdByUserId': null,
      'createdByUsername': null,
      'averageRating': 4.5,
      'reviewCount': 2,
      'reviews': [],
    };

void main() {
  test('서버 응답을 그대로 읽는다', () {
    final place = PlaceDetail.fromJson(_json());

    expect(place.id, 12);
    expect(place.name, '성북구립도서관');
    expect(place.typeLabel, '도서관');
    expect(place.openStatusLabel, '영업중');
    expect(place.scores.seating, 5);
    expect(place.weatherScores.sunny, 2);
    expect(place.warnings, ['음식물 반입 금지']);
    expect(place.tags, ['조용함', '와이파이']);
    expect(place.saved, isTrue);
    expect(place.averageRating, 4.5);
    expect(place.reviewCount, 2);
  });

  test('표시 문구는 웹과 같은 규칙을 쓴다', () {
    final place = PlaceDetail.fromJson(_json());

    // 추정 비용이 0원이면 가격 라벨을 그대로 씁니다.
    expect(place.costLabel, '무료');
    expect(place.spaceLabel, '실내');
    expect(place.stayLabel, '30분-3시간');
    expect(place.hasRating, isTrue);
  });

  test('후기가 없으면 별점을 숨긴다', () {
    final place = PlaceDetail.fromJson({
      ..._json(),
      'averageRating': null,
      'reviewCount': 0,
    });

    expect(place.hasRating, isFalse);
  });

  test('빈 문자열은 값이 없는 것으로 본다', () {
    final place = PlaceDetail.fromJson({
      ..._json(),
      'description': '   ',
      'openingHoursText': '',
      'source': '',
      'sourceUrl': null,
    });

    expect(place.description, isNull);
    expect(place.openingHoursText, isNull);
    expect(place.source, isNull);
    expect(place.sourceUrl, isNull);
  });

  test('필드가 빠져도 기본값으로 읽는다', () {
    // 서버가 새 필드를 추가하거나 일부를 생략해도 화면이 죽지 않아야 합니다.
    final place = PlaceDetail.fromJson({'id': 1, 'name': '이름만 있는 장소'});

    expect(place.typeLabel, isEmpty);
    expect(place.scores.seating, 0);
    expect(place.weatherScores.rain, 0);
    expect(place.warnings, isEmpty);
    expect(place.tags, isEmpty);
    expect(place.saved, isFalse);
    expect(place.reviewCount, 0);
    expect(place.spaceLabel, '정보 없음');
  });

  test('점수는 0~5 범위로 자른다', () {
    final place = PlaceDetail.fromJson({
      ..._json(),
      'scores': {'seating': 9, 'wifi': -3},
    });

    expect(place.scores.seating, 5);
    expect(place.scores.wifi, 0);
  });
}
