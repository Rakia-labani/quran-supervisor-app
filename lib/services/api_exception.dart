// lib/services/api_exception.dart

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/constants.dart';

/// نوع الخطأ: بدل ما نخمّن من نص الرسالة (contains('401')) نعتمد على النوع.
enum ApiErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  parse,
  unknown,
}

/// خطأ موحّد للتعامل مع الـ API: نوع + رسالة + رمز الحالة (إن وجد).
class ApiException implements Exception {
  final ApiErrorType type;
  final String message;
  final int? statusCode;

  const ApiException(this.type, this.message, {this.statusCode});

  /// يبني الخطأ المناسب من رمز حالة HTTP.
  factory ApiException.fromStatus(int statusCode, String message) {
    final ApiErrorType type;
    if (statusCode == 401) {
      type = ApiErrorType.unauthorized;
    } else if (statusCode == 403) {
      type = ApiErrorType.forbidden;
    } else if (statusCode == 404) {
      type = ApiErrorType.notFound;
    } else if (statusCode == 422) {
      type = ApiErrorType.validation;
    } else if (statusCode >= 500) {
      type = ApiErrorType.server;
    } else {
      type = ApiErrorType.unknown;
    }
    return ApiException(type, message, statusCode: statusCode);
  }

  /// يحوّل أي خطأ (SocketException، TimeoutException...) إلى ApiException.
  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is TimeoutException) {
      return const ApiException(ApiErrorType.timeout, AppStrings.timeoutError);
    }
    if (error is IOException || error is http.ClientException) {
      return const ApiException(ApiErrorType.network, AppStrings.networkError);
    }
    if (error is FormatException) {
      return ApiException(ApiErrorType.parse, error.message);
    }
    return ApiException(
      ApiErrorType.unknown,
      error.toString().replaceFirst('Exception: ', ''),
    );
  }

  /// الأخطاء المؤقتة فقط هي اللي بنعيد المحاولة فيها.
  bool get isRetryable =>
      type == ApiErrorType.network || type == ApiErrorType.timeout;

  @override
  String toString() => message;
}

final RegExp _arabicChars = RegExp(r'[\u0600-\u06FF]');

// رسالة الخادم بتنعرض بس لو كانت عربية، وإلا منستخدم الرسالة الافتراضية
String _arabicOr(String message, String fallback) =>
    _arabicChars.hasMatch(message) ? message : fallback;

/// الرسالة اللي بتنعرض للمستخدمة لأي خطأ.
String userMessageFor(Object error) {
  final e = ApiException.from(error);
  switch (e.type) {
    case ApiErrorType.network:
      return AppStrings.networkError;
    case ApiErrorType.timeout:
      return AppStrings.timeoutError;
    case ApiErrorType.unauthorized:
      return AppStrings.unauthorizedError;
    case ApiErrorType.server:
      return AppStrings.serverError;
    case ApiErrorType.forbidden:
      return _arabicOr(e.message, 'ليس لديك صلاحية للوصول إلى هذه الصفحة');
    case ApiErrorType.notFound:
      return 'الصفحة المطلوبة غير موجودة';
    case ApiErrorType.validation:
      return _arabicOr(e.message, 'بيانات غير صالحة، يرجى التحقق من المدخلات');
    case ApiErrorType.parse:
      return 'خطأ في تنسيق البيانات';
    case ApiErrorType.unknown:
      return AppStrings.unknownError;
  }
}
