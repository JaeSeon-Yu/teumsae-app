import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/features/saved/saved_place.dart';

void main() {
  test('서버 응답을 그대로 읽는다', () {
    final place = SavedPlace.fromJson({
      'id': 3,
      'name': '성북구립도서관',
      'typeLabel': '도서관',
      'address': '서울 성북구 화랑로',
      'priceLabel': '무료',
      'estimatedCostMin': 0,
      'estimatedCostMax': 0,
      'indoor': true,
      'outdoor': false,
      'stayMinutesMin': 30,
      'stayMinutesMax': 180,
      'tags': ['조용함', '와이파이'],
      'savedAt': '2026-08-28T10:00:00',
    });

    expect(place.id, 3);
    expect(place.name, '성북구립도서관');
    expect(place.tags, ['조용함', '와이파이']);
    expect(place.costLabel, '무료');
    expect(place.spaceLabel, '실내');
    expect(place.stayLabel, '30분-3시간');
    expect(place.savedAtLabel, '2026. 8. 28. 저장');
  });

  test('저장 시각이 없으면 라벨도 없다', () {
    final place = SavedPlace.fromJson({'id': 1, 'name': '이름만 있는 장소'});

    expect(place.savedAt, isNull);
    expect(place.savedAtLabel, isNull);
    expect(place.tags, isEmpty);
    expect(place.spaceLabel, '정보 없음');
  });
}
