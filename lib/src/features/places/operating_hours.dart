/// 요일 묶음에 붙일 배지 색. 웹 `OperatingHoursView`의 분기와 같습니다.
enum OperatingHoursTone { neutral, positive, caution, danger }

/// 운영시간 한 줄. 예) "평일 09:00-18:00" → days: 평일, time: 09:00-18:00
class OperatingHoursEntry {
  const OperatingHoursEntry({
    required this.days,
    required this.time,
    required this.isClosed,
    required this.isAllDay,
    required this.tone,
  });

  final String days;

  /// 시각 표기가 없으면 빈 문자열.
  final String time;

  /// 휴무·휴관.
  final bool isClosed;

  /// 24시간 운영.
  final bool isAllDay;

  final OperatingHoursTone tone;
}

/// 서버 `openingHoursText`는 자유 형식 문자열이라 화면에서 나눠 씁니다.
///
/// 공공데이터마다 구분자가 달라서 `|`가 있으면 그것을, 없으면 `/`를 씁니다.
/// (웹 `OperatingHoursView`와 같은 규칙을 유지해야 같은 장소가 같게 보입니다.)
abstract final class OperatingHours {
  static final _timePattern = RegExp(r'\d{1,2}:\d{2}');
  static final _closedPattern = RegExp('휴무|휴관');
  static final _allDayPattern = RegExp('24시간( 운영)?');

  static List<OperatingHoursEntry> parse(String? openingHoursText) {
    final raw = openingHoursText?.trim() ?? '';
    if (raw.isEmpty) {
      return const [];
    }

    final separator = raw.contains('|') ? '|' : '/';

    return raw
        .split(separator)
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .map(_toEntry)
        .toList(growable: false);
  }

  static OperatingHoursEntry _toEntry(String item) {
    final isClosed = _closedPattern.hasMatch(item);
    final isAllDay = item.contains('24시간');

    var days = item;
    var time = '';

    final timeMatch = _timePattern.firstMatch(item);
    if (timeMatch != null) {
      days = item.substring(0, timeMatch.start).trim();
      time = item.substring(timeMatch.start).trim();
    } else if (isClosed) {
      days = item.replaceFirst(_closedPattern, '').trim();
    } else if (isAllDay) {
      days = item.replaceFirst(_allDayPattern, '').trim();
    }

    if (days.isEmpty) {
      days = isClosed
          ? '특정일'
          : isAllDay
              ? '매일'
              : '운영시간';
    }

    return OperatingHoursEntry(
      days: days,
      time: time,
      isClosed: isClosed,
      isAllDay: isAllDay,
      tone: _toneOf(days: days, item: item),
    );
  }

  static OperatingHoursTone _toneOf({
    required String days,
    required String item,
  }) {
    if (days.contains('공휴일') || item.contains('공휴일')) {
      return OperatingHoursTone.danger;
    }
    // 평일을 주말보다 먼저 봅니다. "평일"에도 '일'이 들어 있어서 순서를 뒤집으면
    // 평일이 주말 색으로 보입니다. (웹은 이 순서가 뒤집혀 있어 평일이 주말 색입니다)
    if (days.contains('평일') || days.contains('월')) {
      return OperatingHoursTone.positive;
    }
    if (days.contains('주말') || days.contains('토') || days.contains('일')) {
      return OperatingHoursTone.caution;
    }
    return OperatingHoursTone.neutral;
  }
}
