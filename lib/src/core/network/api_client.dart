import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_store.dart';
import 'api_exception.dart';
import 'auth_tokens.dart';

/// 서버 통신 단일 진입점.
///
/// 하는 일:
/// - 저장된 access token을 `Authorization: Bearer`로 붙입니다.
/// - 401을 받으면 `/api/auth/token/refresh`로 한 번 갱신하고 원 요청을 재시도합니다.
/// - 갱신까지 실패하면 토큰을 지우고 [onSessionExpired]로 알립니다.
/// - `DioException`을 화면에서 그대로 쓸 수 있는 [ApiException]으로 바꿉니다.
class ApiClient {
  ApiClient({
    required TokenStore tokenStore,
    Dio? dio,
    Dio? refreshDio,
    this.onSessionExpired,
  })  : _tokenStore = tokenStore,
        _dio = dio ?? Dio(_baseOptions()),
        // 갱신 요청은 인터셉터를 타지 않는 별도 Dio로 보냅니다.
        // 같은 Dio를 쓰면 갱신 실패(401)가 다시 갱신을 부르는 무한 루프가 됩니다.
        _refreshDio = refreshDio ?? Dio(_baseOptions()) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final TokenStore _tokenStore;
  final Dio _dio;
  final Dio _refreshDio;

  /// 재로그인이 필요해졌을 때 호출됩니다. (라우터에서 로그인 화면으로 보내는 용도)
  final void Function()? onSessionExpired;

  /// 동시에 여러 요청이 401을 받아도 갱신은 한 번만 수행하기 위한 잠금.
  Future<AuthTokens?>? _refreshInFlight;

  static const _tokenPathPrefix = '/api/auth/token';

  /// 토큰 없이 호출하는 경로. 여기에 Authorization을 붙이면 만료된 토큰 때문에
  /// 로그인 자체가 401로 막힐 수 있습니다.
  static const _publicPaths = <String>{
    '$_tokenPathPrefix/login',
    '$_tokenPathPrefix/signup',
    '$_tokenPathPrefix/social',
    '$_tokenPathPrefix/firebase',
    '$_tokenPathPrefix/refresh',
  };

  static BaseOptions _baseOptions() => BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        headers: const {'Accept': 'application/json'},
      );

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_publicPaths.contains(options.path)) {
      return handler.next(options);
    }

    final tokens = await _tokenStore.read();
    if (tokens == null) {
      return handler.next(options);
    }

    // 만료가 임박하면 요청을 보내기 전에 미리 갱신해 불필요한 401을 줄입니다.
    final usable = tokens.isExpired() ? await _refreshTokens(tokens) : tokens;
    if (usable != null) {
      options.headers['Authorization'] = usable.authorizationHeader;
    }

    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = error.response?.statusCode == 401;
    final isRetry = error.requestOptions.extra['teumsae_retried'] == true;
    final isPublic = _publicPaths.contains(error.requestOptions.path);

    if (!isUnauthorized || isRetry || isPublic) {
      return handler.reject(error);
    }

    final current = await _tokenStore.read();
    if (current == null) {
      return handler.reject(error);
    }

    final refreshed = await _refreshTokens(current);
    if (refreshed == null) {
      return handler.reject(error);
    }

    try {
      final options = error.requestOptions
        ..headers['Authorization'] = refreshed.authorizationHeader
        ..extra['teumsae_retried'] = true;

      handler.resolve(await _dio.fetch(options));
    } on DioException catch (retryError) {
      handler.reject(retryError);
    }
  }

  /// 성공하면 새 토큰, 실패하면 `null`. 실패 시 저장된 토큰을 지웁니다.
  Future<AuthTokens?> _refreshTokens(AuthTokens current) {
    return _refreshInFlight ??= _performRefresh(current).whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<AuthTokens?> _performRefresh(AuthTokens current) async {
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '$_tokenPathPrefix/refresh',
        data: {'refreshToken': current.refreshToken},
      );

      final tokens = AuthTokens.fromJson(response.data!);
      await _tokenStore.write(tokens);
      return tokens;
    } on DioException {
      // 만료·재사용된 refresh token은 서버가 401로 돌려줍니다. 이때는 재로그인뿐입니다.
      await _tokenStore.clear();
      onSessionExpired?.call();
      return null;
    }
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      return response.data ?? const {};
    });
  }

  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    return _guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      return response.data ?? const {};
    });
  }

  /// 204를 돌려주는 엔드포인트(로그아웃 등)용.
  Future<void> postEmpty(String path, {Object? body}) async {
    await _guard(() async {
      await _dio.post<void>(path, data: body);
      return const <String, dynamic>{};
    });
  }

  Future<Map<String, dynamic>> _guard(
    Future<Map<String, dynamic>> Function() send,
  ) async {
    try {
      return await send();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
