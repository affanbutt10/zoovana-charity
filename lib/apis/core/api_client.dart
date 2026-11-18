import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../app/core/config/app_config.dart';
import '../../app/core/errors/app_error.dart';
import '../../app/core/errors/app_error_mapper.dart';
import '../../app/core/services/app_locale.dart';
import '../../app/core/services/credential_store.dart';

/// Returns a fresh access token, or null when the session can't be renewed.
typedef TokenRefresher = Future<String?> Function();

/// HTTP clients for the auth service and the feeding module. Both send the
/// bearer token and `Accept-Language`, refresh once on `token_expired`, and
/// turn error envelopes into [AppError]s.
class ApiClient {
  ApiClient(this._credentials)
    : auth = _create(AppConfig.authBaseUrl),
      feeding = _create(AppConfig.feedingBaseUrl) {
    for (final dio in [auth, feeding]) {
      dio.interceptors.add(_SessionInterceptor(this, dio));
      if (kDebugMode) {
        dio.interceptors.add(
          LogInterceptor(requestBody: true, responseBody: true),
        );
      }
    }
  }

  final CredentialStore _credentials;
  final Dio auth;
  final Dio feeding;

  /// Set by the session repository, which owns the refresh call.
  TokenRefresher? tokenRefresher;

  /// Called when the refresh token is rejected, so the app can show login.
  VoidCallback? onSessionExpired;

  Future<String?>? _refreshing;

  /// Marks a request that must not carry or refresh the bearer token.
  static Options get anonymous => Options(extra: const {_skipAuth: true});

  /// Longer timeouts for media uploads.
  static Options get upload => Options(
    sendTimeout: AppConfig.uploadTimeout,
    receiveTimeout: AppConfig.uploadTimeout,
  );

  static const _skipAuth = 'skip_auth';
  static const _retried = 'retried';

  static Dio _create(String baseUrl) => Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: const {'Accept': 'application/json'},
    ),
  );

  /// Runs at most one refresh at a time; concurrent 401s wait for it.
  Future<String?> _refresh() {
    final refresher = tokenRefresher;
    if (refresher == null) return Future.value();
    return _refreshing ??= refresher().whenComplete(() => _refreshing = null);
  }
}

class _SessionInterceptor extends Interceptor {
  _SessionInterceptor(this._client, this._dio);

  final ApiClient _client;
  final Dio _dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = AppLocale.code;
    final token = _client._credentials.accessToken;
    if (options.extra[ApiClient._skipAuth] != true && token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    if (response == null) return handler.next(err);
    var error = AppErrorMapper.fromResponse(response.statusCode, response.data);
    if (response.statusCode == 429) {
      error = AppError(
        type: error.type,
        message: error.message,
        statusCode: error.statusCode,
        code: error.code,
        canRetry: error.canRetry,
        details: {
          ...error.details,
          'retry_after': response.headers.value('retry-after'),
        },
      );
    }
    final options = err.requestOptions;
    final canRefresh =
        error.hasCode(ApiErrorCode.tokenExpired) &&
        options.extra[ApiClient._skipAuth] != true &&
        options.extra[ApiClient._retried] != true;
    if (canRefresh) {
      final token = await _client._refresh();
      if (token != null) {
        try {
          final data = options.data;
          final retry = await _dio.fetch<dynamic>(
            options
              // A sent multipart body can't be streamed twice.
              ..data = data is FormData ? data.clone() : data
              ..extra[ApiClient._retried] = true
              ..headers['Authorization'] = 'Bearer $token',
          );
          return handler.resolve(retry);
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      }
      _client.onSessionExpired?.call();
    }
    handler.next(err.copyWith(error: error));
  }
}
