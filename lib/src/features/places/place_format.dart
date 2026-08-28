/// 웹 `src/lib/format.ts`를 옮긴 표시 규칙입니다.
/// 같은 값이 웹과 앱에서 다르게 보이지 않도록, 바꿀 때는 양쪽을 함께 수정해 주세요.
abstract final class PlaceFormat {
  /// 1km 미만은 m, 그 이상은 km.
  static String distance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
    return '${meters}m';
  }

  /// 2시간 이상 머물 수 있으면 시간 단위로 줄여 씁니다.
  static String stayRange(int minMinutes, int maxMinutes) {
    if (maxMinutes >= 120) {
      return '$minMinutes분-${(maxMinutes / 60).round()}시간';
    }
    return '$minMinutes-$maxMinutes분';
  }

  /// 추정 비용이 없거나 0원이면 서버가 준 가격 라벨(무료 등)을 그대로 씁니다.
  static String cost(int? min, int? max, String label) {
    if (min == null || max == null) {
      return label;
    }
    if (min == 0 && max == 0) {
      return label;
    }
    return '${_thousands(min)}-${_thousands(max)}원';
  }

  static String space({required bool indoor, required bool outdoor}) {
    if (indoor && outdoor) return '실내/실외';
    if (indoor) return '실내';
    if (outdoor) return '실외';
    return '정보 없음';
  }

  /// `toLocaleString()` 대응. intl 없이 세 자리마다 쉼표를 넣습니다.
  static String _thousands(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }

    return buffer.toString();
  }
}
