// lib/services/api_response_parser.dart

import 'dart:convert';

import 'api_exception.dart';
import '../constants/constants.dart';

/// تحويل رد الخادم (رمز الحالة + النص) إلى بيانات أو ApiException.
/// منفصل عن ApiService عشان نقدر نختبره بدون شبكة.
class ApiResponseParser {
  /// يرجّع الـ JSON عند النجاح (200/201)، أو يرمي ApiException مناسب.
  static Map<String, dynamic> parse(int statusCode, String body) {
    switch (statusCode) {
      case 200:
      case 201:
        final decoded = _tryDecode(body);
        if (decoded == null) {
          throw ApiException(
            ApiErrorType.parse,
            'خطأ في تنسيق البيانات',
            statusCode: statusCode,
          );
        }
        return decoded;
      case 401:
      case 403:
      case 404:
      case 422:
        throw ApiException.fromStatus(
          statusCode,
          extractErrorMessage(_tryDecode(body) ?? <String, dynamic>{}),
        );
      default:
        if (statusCode >= 500) {
          throw ApiException.fromStatus(statusCode, AppStrings.serverError);
        }
        throw ApiException.fromStatus(
          statusCode,
          'حدث خطأ غير متوقع: $statusCode',
        );
    }
  }

  // فك JSON بأمان: لو الرد مش JSON (صفحة خطأ HTML مثلاً) منرجع null
  static Map<String, dynamic>? _tryDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  // استخراج رسالة الخطأ من استجابة الخادم
  static String extractErrorMessage(Map<String, dynamic> responseData) {
    // التحقق من وجود رسالة خطأ مباشرة
    if (responseData['message'] != null) {
      // ترجمة رسائل الخطأ الشائعة
      switch (responseData['message']) {
        case 'messages.invalid_credentials':
          return 'بيانات الاعتماد غير صحيحة، يرجى التحقق من رقم الهاتف وكلمة المرور';
        case 'messages.account_blocked':
          return 'حسابك محظور، يرجى التواصل مع الإدارة';
        case 'messages.account_not_verified':
          return 'حسابك لم يتم التحقق منه، يرجى التحقق من بريدك الإلكتروني';
        case 'The number field is required.':
          return 'رقم الهاتف مطلوب';
        case 'The password field is required.':
          return 'كلمة المرور مطلوبة';
        default:
          return translateErrorMessage(responseData['message'].toString());
      }
    }

    // التحقق من وجود أخطاء في الحقول
    if (responseData['errors'] != null) {
      final errors = responseData['errors'] as Map<String, dynamic>;
      // أخذ أول خطأ في الحقول
      if (errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return translateErrorMessage(firstError.first.toString());
        } else {
          return translateErrorMessage(firstError.toString());
        }
      }
    }

    // رسالة خطأ افتراضية
    return 'حدث خطأ، يرجى المحاولة مرة أخرى';
  }

  // ترجمة رسائل الخطأ الشائعة
  static String translateErrorMessage(String message) {
    switch (message) {
      case 'The number field is required.':
        return 'رقم الهاتف مطلوب';
      case 'The password field is required.':
        return 'كلمة المرور مطلوبة';
      case 'The password field must be at least 8 characters.':
        return 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';
      case 'The email field is required.':
        return 'حقل البريد الإلكتروني مطلوب';
      case 'These credentials do not match our records.':
        return 'بيانات الاعتماد غير صحيحة';
      case 'Too many login attempts. Please try again in :seconds seconds.':
        return 'محاولات تسجيل دخول كثيرة، يرجى المحاولة لاحقاً';
      default:
        return message;
    }
  }
}
