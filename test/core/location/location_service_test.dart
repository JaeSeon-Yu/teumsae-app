import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/core/location/location_service.dart';

void main() {
  // 웹 `SearchView.moveToCurrentLocation`과 같은 문구를 씁니다.
  // 같은 서비스에서 같은 상황에 다른 말이 나오면 안내가 어긋납니다.
  test('권한 거부·조회 실패 문구는 웹과 같다', () {
    expect(
      LocationFailure.permissionDenied.message,
      '현재 위치 권한을 허용해 주세요.',
    );
    expect(LocationFailure.unavailable.message, '현재 위치를 가져오지 못했습니다.');
  });

  test('예외는 이유의 문구를 그대로 노출한다', () {
    const exception = LocationException(LocationFailure.serviceDisabled);

    expect(exception.message, '기기의 위치 서비스가 꺼져 있습니다.');
  });

  test('고정 구현은 준 좌표를 그대로 돌려준다', () async {
    const service = FixedLocationService(UserLocation(lat: 37.5, lng: 127.1));

    expect(await service.current(), const UserLocation(lat: 37.5, lng: 127.1));
  });

  test('실패 구현은 지정한 이유로 예외를 던진다', () {
    const service = FailingLocationService(
      LocationFailure.permissionDeniedForever,
    );

    expect(
      service.current,
      throwsA(
        isA<LocationException>().having(
          (error) => error.failure,
          'failure',
          LocationFailure.permissionDeniedForever,
        ),
      ),
    );
  });
}
