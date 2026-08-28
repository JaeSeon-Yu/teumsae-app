import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/features/places/operating_hours.dart';

void main() {
  test('비어 있으면 항목이 없다', () {
    expect(OperatingHours.parse(null), isEmpty);
    expect(OperatingHours.parse(''), isEmpty);
    expect(OperatingHours.parse('   '), isEmpty);
  });

  test('파이프가 있으면 파이프로 나눈다', () {
    final entries = OperatingHours.parse(
      '평일 09:00-18:00 | 토요일 09:00-13:00',
    );

    expect(entries, hasLength(2));
    expect(entries.first.days, '평일');
    expect(entries.first.time, '09:00-18:00');
    expect(entries.last.days, '토요일');
  });

  test('파이프가 없으면 슬래시로 나눈다', () {
    final entries = OperatingHours.parse('평일 09:00-18:00 / 일요일 휴무');

    expect(entries, hasLength(2));
    expect(entries.last.days, '일요일');
    expect(entries.last.isClosed, isTrue);
  });

  test('시각 표기가 있으면 요일과 시각을 나눈다', () {
    final entry = OperatingHours.parse('월~금 10:30-19:00').single;

    expect(entry.days, '월~금');
    expect(entry.time, '10:30-19:00');
    expect(entry.isClosed, isFalse);
    expect(entry.isAllDay, isFalse);
  });

  test('휴무는 요일만 남기고 표시한다', () {
    final entry = OperatingHours.parse('일요일 휴관').single;

    expect(entry.days, '일요일');
    expect(entry.time, isEmpty);
    expect(entry.isClosed, isTrue);
  });

  test('24시간 운영은 요일이 없으면 매일로 채운다', () {
    final entry = OperatingHours.parse('24시간 운영').single;

    expect(entry.days, '매일');
    expect(entry.isAllDay, isTrue);
    expect(entry.time, isEmpty);
  });

  group('배지 색', () {
    test('공휴일이 가장 우선한다', () {
      // 평일·공휴일이 함께 있으면 공휴일 쪽으로 표시해 실수로 헛걸음하지 않게 합니다.
      final entry = OperatingHours.parse('평일·공휴일 09:00-18:00').single;

      expect(entry.tone, OperatingHoursTone.danger);
    });

    test('주말은 주의 색을 쓴다', () {
      expect(
        OperatingHours.parse('토요일 09:00-13:00').single.tone,
        OperatingHoursTone.caution,
      );
    });

    test('평일은 기본 색을 쓴다', () {
      // "평일"에도 '일'이 들어 있어 주말 판정보다 먼저 봐야 합니다.
      expect(
        OperatingHours.parse('평일 09:00-18:00').single.tone,
        OperatingHoursTone.positive,
      );
    });

    test('요일을 알 수 없으면 중립 색을 쓴다', () {
      expect(
        OperatingHours.parse('상시 개방').single.tone,
        OperatingHoursTone.neutral,
      );
    });
  });
}
