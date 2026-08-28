import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/features/places/place_summary.dart';

void main() {
  test('서버가 준 좌표를 마커용으로 파싱한다', () {
    final place = PlaceSummary.fromJson(const {
      'id': 1,
      'name': '성북구립도서관',
      'lat': 37.5921,
      'lng': 127.0161,
    });

    expect(place.lat, 37.5921);
    expect(place.lng, 127.0161);
  });

  test('좌표가 없으면 0으로 둔다', () {
    // 서버 `PlaceSummaryResponse`는 좌표를 항상 주지만, 응답이 바뀌어도
    // 파싱에서 죽지 않게 합니다. 지도에서는 마커가 엉뚱한 곳에 찍히는 대신
    // 목록은 그대로 보입니다.
    final place = PlaceSummary.fromJson(const {'id': 1, 'name': '이름만'});

    expect(place.lat, 0);
    expect(place.lng, 0);
  });
}
