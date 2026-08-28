import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/features/places/place_format.dart';

void main() {
  group('distance', () {
    test('1km 미만은 m로 표시한다', () {
      expect(PlaceFormat.distance(0), '0m');
      expect(PlaceFormat.distance(999), '999m');
    });

    test('1km 이상은 소수 한 자리 km로 표시한다', () {
      expect(PlaceFormat.distance(1000), '1.0km');
      expect(PlaceFormat.distance(1540), '1.5km');
    });
  });

  group('stayRange', () {
    test('2시간 미만은 분으로 표시한다', () {
      expect(PlaceFormat.stayRange(10, 60), '10-60분');
    });

    test('2시간 이상은 시간으로 줄여 쓴다', () {
      expect(PlaceFormat.stayRange(30, 120), '30분-2시간');
      expect(PlaceFormat.stayRange(30, 150), '30분-3시간');
    });
  });

  group('cost', () {
    test('추정 비용이 없으면 가격 라벨을 그대로 쓴다', () {
      expect(PlaceFormat.cost(null, null, '무료'), '무료');
      expect(PlaceFormat.cost(1000, null, '무료'), '무료');
    });

    test('0원 구간도 가격 라벨을 쓴다', () {
      expect(PlaceFormat.cost(0, 0, '무료'), '무료');
    });

    test('세 자리마다 쉼표를 넣는다', () {
      expect(PlaceFormat.cost(1000, 12000, '유료'), '1,000-12,000원');
      expect(PlaceFormat.cost(0, 1500000, '유료'), '0-1,500,000원');
    });
  });

  group('space', () {
    test('실내·실외 조합을 라벨로 바꾼다', () {
      expect(PlaceFormat.space(indoor: true, outdoor: true), '실내/실외');
      expect(PlaceFormat.space(indoor: true, outdoor: false), '실내');
      expect(PlaceFormat.space(indoor: false, outdoor: true), '실외');
      expect(PlaceFormat.space(indoor: false, outdoor: false), '정보 없음');
    });
  });
}
