import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/features/places/place_detail.dart';
import 'package:teumsae_app/src/features/places/place_form.dart';

PlaceDetail _detail(Map<String, dynamic> overrides) => PlaceDetail.fromJson({
      'id': 1,
      'name': '성북구립도서관',
      'type': 'LIBRARY',
      'address': '서울 성북구 화랑로',
      'lat': 37.5921,
      'lng': 127.0161,
      'priceLevel': 'FREE',
      'indoor': true,
      'outdoor': false,
      'stayMinutesMin': 30,
      'stayMinutesMax': 180,
      ...overrides,
    });

void main() {
  group('기본값', () {
    test('웹 폼과 같은 기본값으로 시작한다', () {
      const values = PlaceFormValues();

      expect(values.type, PlaceTypeOption.publicFacility);
      expect(values.priceLevel, PriceLevelOption.free);
      expect(values.estimatedCostMin, '0');
      expect(values.estimatedCostMax, '0');
      expect(values.stayMinutesMin, 15);
      expect(values.stayMinutesMax, 60);
      expect(values.indoor, isTrue);
      expect(values.outdoor, isFalse);
      expect(values.seating, isTrue);
      expect(values.openingHoursMode, OpeningHoursMode.range);
      // 좌표 기본값은 검색과 같은 성북구 부근입니다.
      expect(values.lat, 37.592);
      expect(values.lng, 127.016);
    });

    test('사용자가 고를 수 없는 유형·테마는 목록에 없다', () {
      // 공공데이터 동기화로만 들어오는 유형입니다.
      final typeValues = PlaceTypeOption.values.map((type) => type.value);
      expect(typeValues, isNot(contains('TRADITIONAL_MARKET')));
      expect(typeValues, isNot(contains('LARGE_SCALE_RETAIL')));

      // ANY는 검색 필터 전용, TOILET은 유형에서 파생됩니다.
      final themeValues = PlaceThemeOption.values.map((theme) => theme.value);
      expect(themeValues, isNot(contains('ANY')));
      expect(themeValues, isNot(contains('TOILET')));
    });
  });

  group('검증', () {
    test('통과하는 값은 null을 준다', () {
      expect(const PlaceFormValues(name: '틈새 쉼터').validate(), isNull);
    });

    test('이름이 비면 막는다', () {
      expect(const PlaceFormValues(name: '   ').validate(), '장소 이름을 입력해 주세요.');
    });

    test('이름 80자를 넘으면 막는다', () {
      expect(
        PlaceFormValues(name: '가' * 81).validate(),
        '장소 이름은 80자 이하로 입력해 주세요.',
      );
      expect(PlaceFormValues(name: '가' * 80).validate(), isNull);
    });

    test('실내·실외를 모두 끄면 막는다', () {
      // 서버 `CreatePlaceRequest.validate()`와 같은 규칙입니다.
      const values = PlaceFormValues(
        name: '틈새',
        indoor: false,
        outdoor: false,
      );

      expect(values.validate(), '실내 또는 실외 중 하나는 선택해야 합니다.');
    });

    test('좌표 범위를 벗어나면 막는다', () {
      expect(
        const PlaceFormValues(name: '틈새', lat: 91).validate(),
        '지도 위치 좌표가 올바르지 않습니다.',
      );
      expect(
        const PlaceFormValues(name: '틈새', lng: -181).validate(),
        '지도 위치 좌표가 올바르지 않습니다.',
      );
    });

    test('체류 시간은 1~1440분만 받는다', () {
      expect(
        const PlaceFormValues(name: '틈새', stayMinutesMin: 0).validate(),
        '체류 시간은 1분부터 1440분까지 입력할 수 있습니다.',
      );
      expect(
        const PlaceFormValues(name: '틈새', stayMinutesMax: 1441).validate(),
        '체류 시간은 1분부터 1440분까지 입력할 수 있습니다.',
      );
    });

    test('최소 체류가 최대보다 크면 막는다', () {
      const values = PlaceFormValues(
        name: '틈새',
        stayMinutesMin: 120,
        stayMinutesMax: 60,
      );

      expect(values.validate(), '최소 체류 시간은 최대 체류 시간보다 클 수 없습니다.');
    });

    test('비용은 0~1,000,000원만 받는다', () {
      expect(
        const PlaceFormValues(name: '틈새', estimatedCostMax: '1000001')
            .validate(),
        '비용은 0원부터 1,000,000원까지 숫자로 입력해 주세요.',
      );
      // 비어 있으면 "상관없음"으로 보내므로 통과합니다.
      expect(
        const PlaceFormValues(
          name: '틈새',
          estimatedCostMin: '',
          estimatedCostMax: '',
        ).validate(),
        isNull,
      );
    });

    test('최소 비용이 최대보다 크면 막는다', () {
      const values = PlaceFormValues(
        name: '틈새',
        estimatedCostMin: '5000',
        estimatedCostMax: '1000',
      );

      expect(values.validate(), '최소 비용은 최대 비용보다 클 수 없습니다.');
    });

    test('태그는 8개까지만 받는다', () {
      final values = PlaceFormValues(
        name: '틈새',
        tags: {for (var i = 0; i < 9; i++) '태그$i'},
      );

      expect(values.validate(), '태그는 8개까지 고를 수 있습니다.');
    });
  });

  group('운영시간', () {
    test('시간 범위는 HH:MM-HH:MM으로 보낸다', () {
      const values = PlaceFormValues(
        openingHoursStart: '10:00',
        openingHoursEnd: '22:30',
      );

      expect(values.openingHoursText, '10:00-22:30');
    });

    test('24시간은 종일로 보낸다', () {
      const values = PlaceFormValues(
        openingHoursMode: OpeningHoursMode.allDay,
      );

      expect(values.openingHoursText, '종일');
    });

    test('직접 입력이 비면 null로 보낸다', () {
      const values = PlaceFormValues(
        openingHoursMode: OpeningHoursMode.custom,
        openingHoursCustom: '   ',
      );

      expect(values.openingHoursText, isNull);
    });

    test('저장된 값을 입력 상태로 되돌린다', () {
      final range = PlaceFormValues.fromDetail(
        _detail({'openingHoursText': '09:00-18:00'}),
      );
      expect(range.openingHoursMode, OpeningHoursMode.range);
      expect(range.openingHoursStart, '09:00');
      expect(range.openingHoursEnd, '18:00');

      final allDay = PlaceFormValues.fromDetail(
        _detail({'openingHoursText': '종일'}),
      );
      expect(allDay.openingHoursMode, OpeningHoursMode.allDay);

      // 요일 규칙은 앱에서 만들 수 없어 직접 입력으로 들어옵니다.
      final custom = PlaceFormValues.fromDetail(
        _detail({'openingHoursText': '평일 09:00-18:00 | 주말 휴무'}),
      );
      expect(custom.openingHoursMode, OpeningHoursMode.custom);
      expect(custom.openingHoursCustom, '평일 09:00-18:00 | 주말 휴무');
    });
  });

  group('태그와 플래그', () {
    test('편의시설 태그를 고르면 플래그도 켜진다', () {
      const values = PlaceFormValues();

      final next = values.withTags({'와이파이', '조용함'});

      expect(next.wifi, isTrue);
      expect(next.quiet, isTrue);
      // 고르지 않은 것은 꺼집니다. (웹 featurePatchFromTags와 같습니다)
      expect(next.seating, isFalse);
    });

    test('실외만 고르면 실내가 꺼진다', () {
      final next = const PlaceFormValues().withTags({'실외'});

      expect(next.indoor, isFalse);
      expect(next.outdoor, isTrue);
    });

    test('둘 다 고르면 둘 다 켜진다', () {
      final next = const PlaceFormValues().withTags({'실내', '실외'});

      expect(next.indoor, isTrue);
      expect(next.outdoor, isTrue);
    });

    test('아무 태그도 없으면 실내로 둔다', () {
      // 서버가 실내·실외 중 하나를 요구하므로 빈 상태를 만들지 않습니다.
      final next = const PlaceFormValues().withTags({});

      expect(next.indoor, isTrue);
      expect(next.outdoor, isFalse);
    });
  });

  group('수정 폼 초기값', () {
    test('상세 응답에서 선택 상태를 되살린다', () {
      final values = PlaceFormValues.fromDetail(
        _detail({
          'scores': {'seating': 4, 'wifi': 0, 'quiet': 2},
          'tags': ['조용함', '도서관'],
          'themes': ['REST', 'ANY'],
          'estimatedCostMin': 1000,
          'estimatedCostMax': 3000,
          'description': '조용합니다',
        }),
      );

      expect(values.name, '성북구립도서관');
      expect(values.type, PlaceTypeOption.library);
      expect(values.priceLevel, PriceLevelOption.free);
      expect(values.stayMinutesMin, 30);
      expect(values.stayMinutesMax, 180);
      expect(values.estimatedCostMin, '1000');
      expect(values.estimatedCostMax, '3000');
      expect(values.description, '조용합니다');

      // 2점 이상을 선택된 것으로 봅니다. (웹 FEATURE_TAG_THRESHOLD)
      expect(values.seating, isTrue);
      expect(values.quiet, isTrue);
      expect(values.wifi, isFalse);

      // 실내·편의시설 태그가 선택 상태에 더해집니다.
      expect(values.tags, containsAll(<String>['실내', '좌석', '조용함', '도서관']));

      // ANY는 고를 수 없는 테마라 버립니다.
      expect(values.themes, {PlaceThemeOption.rest});
    });

    test('모르는 유형은 기본값으로 둔다', () {
      final values = PlaceFormValues.fromDetail(
        _detail({'type': 'TRADITIONAL_MARKET'}),
      );

      expect(values.type, PlaceTypeOption.publicFacility);
    });
  });

  group('요청 본문', () {
    test('서버가 받는 형태로 만든다', () {
      const values = PlaceFormValues(
        name: '  틈새 쉼터  ',
        type: PlaceTypeOption.park,
        address: '  서울 성북구  ',
        priceLevel: PriceLevelOption.under2000,
        estimatedCostMin: '1000',
        estimatedCostMax: '2000',
        themes: {PlaceThemeOption.rest},
        tags: {'실외', '벤치'},
        description: '  좋아요  ',
      );

      final body = values.toRequestBody();

      // 앞뒤 공백은 다듬어 보냅니다.
      expect(body['name'], '틈새 쉼터');
      expect(body['address'], '서울 성북구');
      expect(body['description'], '좋아요');
      expect(body['type'], 'PARK');
      expect(body['priceLevel'], 'UNDER_2000');
      expect(body['estimatedCostMin'], 1000);
      expect(body['estimatedCostMax'], 2000);
      expect(body['themes'], ['REST']);
      expect(body['tags'], containsAll(<String>['실외', '벤치']));
      expect(body['openingHoursText'], '09:00-18:00');
    });

    test('빈 주소·설명·비용은 null로 보낸다', () {
      const values = PlaceFormValues(
        name: '틈새',
        address: '   ',
        description: '',
        estimatedCostMin: '',
        estimatedCostMax: '',
      );

      final body = values.toRequestBody();

      // 주소를 null로 보내면 서버가 좌표로 찾아 채웁니다.
      expect(body['address'], isNull);
      expect(body['description'], isNull);
      expect(body['estimatedCostMin'], isNull);
      expect(body['estimatedCostMax'], isNull);
    });
  });
}
