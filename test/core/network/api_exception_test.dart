import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teumsae_app/src/core/network/api_exception.dart';

DioException _exception({
  required DioExceptionType type,
  int? statusCode,
  Object? data,
}) {
  final requestOptions = RequestOptions(path: '/api/auth/token/login');

  return DioException(
    requestOptions: requestOptions,
    type: type,
    response: statusCode == null
        ? null
        : Response<Object?>(
            requestOptions: requestOptions,
            statusCode: statusCode,
            data: data,
          ),
  );
}

void main() {
  group('ApiException.fromDioException', () {
    test('서버가 보낸 한글 message를 그대로 쓴다', () {
      final exception = ApiException.fromDioException(
        _exception(
          type: DioExceptionType.badResponse,
          statusCode: 400,
          data: {'status': 400, 'message': '아이디는 4자 이상 20자 이하로 입력해 주세요.'},
        ),
      );

      expect(exception.message, '아이디는 4자 이상 20자 이하로 입력해 주세요.');
      expect(exception.statusCode, 400);
    });

    test('본문 message가 비어 있으면 상태 코드 기반 문구를 쓴다', () {
      final exception = ApiException.fromDioException(
        _exception(
          type: DioExceptionType.badResponse,
          statusCode: 401,
          data: {'status': 401, 'message': '   '},
        ),
      );

      expect(exception.message, '로그인이 필요합니다.');
      expect(exception.isUnauthorized, isTrue);
    });

    test('연결 실패는 네트워크 안내 문구', () {
      final exception = ApiException.fromDioException(
        _exception(type: DioExceptionType.connectionError),
      );

      expect(exception.statusCode, isNull);
      expect(exception.message, '서버에 연결할 수 없습니다. 네트워크 상태를 확인해 주세요.');
    });

    test('타임아웃은 지연 안내 문구', () {
      final exception = ApiException.fromDioException(
        _exception(type: DioExceptionType.receiveTimeout),
      );

      expect(exception.message, '서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.');
    });

    test('5xx는 서버 문제 문구', () {
      final exception = ApiException.fromDioException(
        _exception(type: DioExceptionType.badResponse, statusCode: 503),
      );

      expect(exception.message, '서버에 문제가 발생했습니다. 잠시 후 다시 시도해 주세요.');
    });

    test('409는 중복 판단에 쓸 수 있다', () {
      final exception = ApiException.fromDioException(
        _exception(
          type: DioExceptionType.badResponse,
          statusCode: 409,
          data: {'status': 409, 'message': '이미 사용 중인 아이디입니다: teumsae'},
        ),
      );

      expect(exception.isConflict, isTrue);
      expect(exception.message, contains('이미 사용 중인 아이디입니다'));
    });
  });
}
