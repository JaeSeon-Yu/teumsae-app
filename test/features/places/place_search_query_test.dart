import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/features/places/place_search_query.dart';

void main() {
  group('toQueryParameters', () {
    test('서버가 받는 이름과 값으로 바꾼다', () {
      const query = PlaceSearchQuery(
        radius: 3000,
        stayMinutes: 60,
        theme: SearchTheme.play,
        budget: SearchBudget.under2000,
        space: SearchSpace.indoor,
        needs: {SearchNeed.wifi},
        sort: SearchSort.distance,
        openOnly: true,
      );

      expect(query.toQueryParameters(), {
        'lat': 37.592,
        'lng': 127.016,
        'radius': 3000,
        'stayMinutes': 60,
        'budget': 'UNDER_2000',
        'weather': 'ANY',
        'space': 'INDOOR',
        'needs': 'wifi',
        'sort': 'distance',
        'theme': 'PLAY',
        'openOnly': true,
      });
    });

    test('필요 시설은 쉼표로 이어 보낸다', () {
      const query = PlaceSearchQuery(
        needs: {SearchNeed.seating, SearchNeed.toilet},
      );

      // 서버 `parseNeeds`가 쉼표로 나눠 읽습니다.
      expect(query.toQueryParameters()['needs'], 'seating,toilet');
    });

    test('조건이 없으면 필요 시설은 빈 문자열이다', () {
      // 서버는 빈 값을 "조건 없음"으로 처리합니다.
      expect(const PlaceSearchQuery().toQueryParameters()['needs'], '');
    });
  });

  group('activeFilterCount', () {
    test('기본 조건은 0이다', () {
      expect(const PlaceSearchQuery().activeFilterCount, 0);
    });

    test('바꾼 항목 수를 센다', () {
      const query = PlaceSearchQuery(
        radius: 3000,
        stayMinutes: 30,
        budget: SearchBudget.free,
        space: SearchSpace.outdoor,
        needs: {SearchNeed.wifi, SearchNeed.quiet},
      );

      expect(query.activeFilterCount, 6);
    });

    test('테마·정렬·영업중은 세지 않는다', () {
      // 조건 시트 밖에 있는 항목이라 시트의 배지에 넣으면 헷갈립니다.
      const query = PlaceSearchQuery(
        theme: SearchTheme.toilet,
        sort: SearchSort.distance,
        openOnly: true,
      );

      expect(query.activeFilterCount, 0);
    });
  });

  test('초기화는 시트 안의 항목만 되돌린다', () {
    const query = PlaceSearchQuery(
      radius: 5000,
      stayMinutes: 120,
      budget: SearchBudget.free,
      space: SearchSpace.indoor,
      needs: {SearchNeed.wifi},
      theme: SearchTheme.shopping,
      sort: SearchSort.distance,
      openOnly: true,
    );

    final reset = query.resetFilters();

    expect(reset.activeFilterCount, 0);
    expect(reset.radius, 1500);
    expect(reset.stayMinutes, 0);
    expect(reset.needs, isEmpty);
    // 시트 밖의 항목은 유지합니다.
    expect(reset.theme, SearchTheme.shopping);
    expect(reset.sort, SearchSort.distance);
    expect(reset.openOnly, isTrue);
  });

  test('테마 값은 서버 문자열로 되돌릴 수 있다', () {
    expect(SearchTheme.fromValue('TOILET'), SearchTheme.toilet);
    // 모르는 값은 전체로 둡니다.
    expect(SearchTheme.fromValue('UNKNOWN'), SearchTheme.any);
  });
}
