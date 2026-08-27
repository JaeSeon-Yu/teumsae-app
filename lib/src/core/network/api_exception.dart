import 'package:dio/dio.dart';

/// 서버 에러 응답(`ErrorResponse{status, message}`)을 그대로 담는 예외.
///
/// 서버의 검증 실패 메시지는 이미 한글이므로(`GlobalExceptionHandler`),
/// 화면에서는 [message]를 그대로 보여줘도 됩니다.
/// 네트워크 단절처럼 본문이 없는 경우에만 앱에서 문구를 채웁니다.
class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  /// HTTP 상태 코드. 네트워크 오류 등 응답 자체가 없으면 `null`입니다.
  final int? statusCode;

  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;

  /// Dio 예외를 사용자에게 보여줄 수 있는 한글 문구로 변환합니다.
  factory ApiException.fromDioException(DioException exception) {
    final response = exception.response;
    final serverMessage = _extractMessage(response?.data);

    if (serverMessage != null) {
      return ApiException(
        statusCode: response?.statusCode,
        message: serverMessage,
      );
    }

    final message = switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout =>
        '서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.',
      DioExceptionType.connectionError =>
        '서버에 연결할 수 없습니다. 네트워크 상태를 확인해 주세요.',
      DioExceptionType.cancel => '요청이 취소되었습니다.',
      DioExceptionType.badCertificate => '보안 인증서를 확인할 수 없습니다.',
      DioExceptionType.badResponse => _messageForStatus(response?.statusCode),
      DioExceptionType.unknown => '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.',
    };

    return ApiException(statusCode: response?.statusCode, message: message);
  }

  static String? _extractMessage(Object? data) {
    if (data is Map && data['message'] is String) {
      final message = (data['message'] as String).trim();
      return message.isEmpty ? null : message;
    }
    return null;
  }

  static String _messageForStatus(int? statusCode) {
    return switch (statusCode) {
      400 => '요청 값이 올바르지 않습니다.',
      401 => '로그인이 필요합니다.',
      403 => '접근 권한이 없습니다.',
      404 => '요청한 정보를 찾을 수 없습니다.',
      409 => '이미 존재하는 정보입니다.',
      final int code when code >= 500 => '서버에 문제가 발생했습니다. 잠시 후 다시 시도해 주세요.',
      _ => '요청을 처리할 수 없습니다.',
    };
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
