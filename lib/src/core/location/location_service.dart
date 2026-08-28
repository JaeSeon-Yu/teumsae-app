import 'package:geolocator/geolocator.dart';

/// 현재 위치 좌표. 검색 조건의 `lat`/`lng`에 그대로 들어갑니다.
class UserLocation {
  const UserLocation({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  bool operator ==(Object other) =>
      other is UserLocation && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'UserLocation($lat, $lng)';
}

/// 현재 위치를 가져오지 못한 이유. 화면에 그대로 쓸 한글 문구를 함께 둡니다.
///
/// [permissionDenied]와 [unavailable] 문구는 웹 `SearchView.moveToCurrentLocation`과
/// 같습니다. 나머지 둘은 웹에 없는 앱 전용 상황입니다.
/// (브라우저는 기기 위치 서비스 상태나 영구 거부를 따로 알려 주지 않습니다)
enum LocationFailure {
  /// 기기 설정에서 위치 서비스 자체가 꺼진 상태.
  serviceDisabled('기기의 위치 서비스가 꺼져 있습니다.'),

  /// 권한 요청을 사용자가 거부한 상태. 다시 물어볼 수 있습니다.
  permissionDenied('현재 위치 권한을 허용해 주세요.'),

  /// 영구 거부(Android) 또는 설정에서 차단(iOS). 앱에서 다시 물어볼 수 없습니다.
  permissionDeniedForever('설정에서 위치 권한을 허용해 주세요.'),

  /// 권한은 있으나 좌표를 얻지 못한 경우. (시간 초과·신호 없음 등)
  unavailable('현재 위치를 가져오지 못했습니다.'),
  ;

  const LocationFailure(this.message);

  final String message;
}

class LocationException implements Exception {
  const LocationException(this.failure);

  final LocationFailure failure;

  String get message => failure.message;

  @override
  String toString() => 'LocationException(${failure.name}: $message)';
}

/// 현재 위치 조회. 테스트에서 가짜 구현으로 바꿀 수 있도록 인터페이스로 둡니다.
/// (플랫폼 채널을 타므로 위젯 테스트에서 실제 구현을 쓸 수 없습니다)
abstract interface class LocationService {
  /// 성공하면 좌표를, 실패하면 [LocationException]을 던집니다.
  Future<UserLocation> current();
}

/// `geolocator` 기반 구현. 권한이 없으면 조회 전에 한 번 요청합니다.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService({this.timeout = const Duration(seconds: 10)});

  /// 웹 `getCurrentPosition`의 `timeout`과 같은 값입니다.
  final Duration timeout;

  @override
  Future<UserLocation> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationFailure.permissionDeniedForever);
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw const LocationException(LocationFailure.permissionDenied);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          // 웹도 enableHighAccuracy를 켭니다. 반경 500m 검색에서는 정확도가 결과를 바꿉니다.
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );

      return UserLocation(
        lat: position.latitude,
        lng: position.longitude,
      );
    } on LocationException {
      rethrow;
    } on Object {
      // 시간 초과(TimeoutException)와 플랫폼 예외를 같은 문구로 묶습니다.
      // 사용자가 할 수 있는 조치가 "다시 시도" 하나뿐이라 구분해도 도움이 안 됩니다.
      throw const LocationException(LocationFailure.unavailable);
    }
  }
}

/// 테스트·프리뷰용 구현. 앱 실행 코드에서는 쓰지 않습니다.
class FixedLocationService implements LocationService {
  const FixedLocationService(this.location);

  final UserLocation location;

  @override
  Future<UserLocation> current() async => location;
}

/// 테스트용. 항상 주어진 이유로 실패합니다.
class FailingLocationService implements LocationService {
  const FailingLocationService(this.failure);

  final LocationFailure failure;

  @override
  Future<UserLocation> current() async => throw LocationException(failure);
}
