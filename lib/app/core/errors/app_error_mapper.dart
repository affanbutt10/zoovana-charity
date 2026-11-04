import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'app_error.dart';

abstract final class AppErrorMapper {
  static AppError map(Object error) {
    if (error is AppError) return error;
    if (error is DioException) {
      if (error.error is AppError) return error.error! as AppError;
      return switch (error.type) {
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout => AppError(
          type: AppErrorType.network,
          message: 'Please check your internet connection and try again.'.tr,
          canRetry: true,
        ),
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => AppError(
          type: AppErrorType.network,
          message: 'The request took too long. Please try again.'.tr,
          canRetry: true,
        ),
        DioExceptionType.badResponse => fromResponse(
          error.response?.statusCode,
          error.response?.data,
        ),
        _ => AppError(
          type: AppErrorType.unknown,
          message: 'Something went wrong. Please try again.'.tr,
          canRetry: true,
        ),
      };
    }

    if (error is ArgumentError) {
      return AppError(
        type: AppErrorType.validation,
        message: error.message.toString(),
      );
    }

    return AppError(
      type: AppErrorType.unknown,
      message: 'Something went wrong. Please try again.'.tr,
      canRetry: true,
    );
  }

  /// Reads the `{success: false, message, code, details}` error envelope.
  static AppError fromResponse(int? statusCode, dynamic data) {
    final body = data is Map ? data : const {};
    final details = body['details'] is Map
        ? Map<String, dynamic>.from(body['details'] as Map)
        : const <String, dynamic>{};
    // The guide puts the code at the top; the live auth service currently
    // sends it as `details.error`.
    final code = switch ((body['code'], details['error'])) {
      (final String code, _) => code,
      (_, final String code) => code,
      _ => null,
    };
    final status = statusCode ?? 0;
    return AppError(
      type: switch (status) {
        401 => AppErrorType.unauthorized,
        400 || 422 => AppErrorType.validation,
        _ => AppErrorType.server,
      },
      statusCode: statusCode,
      code: code,
      details: details,
      // A 404 without a code means the route itself is missing on the
      // server, not that the record wasn't found.
      message: status == 404 && code == null
          ? 'This service isn’t available yet. Please try again later.'.tr
          : _responseMessage(body),
      canRetry: status >= 500 || status == 429,
    );
  }

  static String _responseMessage(Map<dynamic, dynamic> data) {
    final message = data['message'] ?? data['error'] ?? data['detail'];
    if (message is String && message.trim().isNotEmpty) return message;
    return 'The service is unavailable right now. Please try again.'.tr;
  }
}
