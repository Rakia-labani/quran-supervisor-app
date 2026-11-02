// lib/services/services.dart

import '../utils/app_logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_manager.dart';
import '../constants/constants.dart';
import 'api_exception.dart';
import 'api_response_parser.dart';

class ApiService {
  // الحصول على التوكن
  static Future<String?> _getToken() async {
    return await TokenManager.getToken();
  }

  // إنشاء رأس الطلب مع التوكن
  static Future<Map<String, String>> _getHeaders(
      {bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ✅ إعادة محاولة تلقائية للطلبات (GET بس - آمن نعيدها لإنها لا تُنشئ بيانات)
  // بتحاول 3 مرات افتراضياً بفواصل متزايدة (1 ثانية، 4 ثواني)، وبترجع
  // الخطأ الأصلي لو فشلت كل المحاولات أو كان الخطأ مش شبكة (401 مثلاً)
  static Future<T> _withRetry<T>(
    Future<T> Function() request, {
    int maxAttempts = 3,
  }) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await request();
      } catch (e) {
        if (!ApiException.from(e).isRetryable || attempt >= maxAttempts) {
          rethrow;
        }

        final delaySeconds = attempt * attempt; // 1s ثم 4s
        appLog(
            'Retryable error, attempt $attempt/$maxAttempts. Retrying in ${delaySeconds}s...');
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
  }

  // التعامل مع أخطاء الاستجابة (المنطق بملف api_response_parser.dart)
  static Map<String, dynamic> _handleResponse(http.Response response) {
    appLog('Response status: ${response.statusCode}');
    return ApiResponseParser.parse(response.statusCode, response.body);
  }

  // تسجيل الدخول
  static Future<Map<String, dynamic>> login(
      String phoneNumber, String password) async {
    try {
      appLog('Attempting login');

      final url =
          Uri.parse('${ApiSettings.baseUrl}${ApiSettings.loginEndpoint}');
      final headers = await _getHeaders(includeAuth: false);

      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'number': phoneNumber,
              'password': password,
            }),
          )
          .timeout(
            Duration(seconds: ApiSettings.connectionTimeout),
            onTimeout: () =>
                throw const ApiException(ApiErrorType.timeout, AppStrings.timeoutError),
          );

      final responseData = _handleResponse(response);

      // حفظ التوكن والوظيفة
      if (responseData['token'] != null) {
        await TokenManager.saveToken(
          responseData['token'],
          responseData['role'] ?? 'user',
        );
        appLog('Login successful, token saved');
      }

      return responseData;
    } catch (e) {
      appLog('Login error: $e');
      rethrow;
    }
  }

  // التحقق من صلاحية التوكن
  static Future<bool> isTokenValid() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      final url =
          Uri.parse('${ApiSettings.baseUrl}${ApiSettings.userEndpoint}');
      final headers = await _getHeaders();

      final response = await http
          .get(
            url,
            headers: headers,
          )
          .timeout(
            Duration(seconds: ApiSettings.connectionTimeout),
            onTimeout: () =>
                throw const ApiException(ApiErrorType.timeout, AppStrings.timeoutError),
          );

      return response.statusCode == 200;
    } catch (e) {
      appLog('Token validation error: $e');
      return false;
    }
  }

  // تسجيل الخروج
  static Future<void> logout() async {
    try {
      final url =
          Uri.parse('${ApiSettings.baseUrl}${ApiSettings.logoutEndpoint}');
      final headers = await _getHeaders();

      await http
          .post(
            url,
            headers: headers,
          )
          .timeout(
            Duration(seconds: ApiSettings.connectionTimeout),
            onTimeout: () =>
                throw const ApiException(ApiErrorType.timeout, AppStrings.timeoutError),
          );

      appLog('Logout successful');
    } catch (e) {
      appLog('Logout error: $e');
    } finally {
      // حذف التوكن محلياً حتى لو فشل تسجيل الخروج في الخادم
      await TokenManager.clearToken();
    }
  }

  // جلب قائمة الطالبات
  static Future<Map<String, dynamic>> getStudents({int page = 1}) async {
    return _withRetry(() async {
      appLog('Fetching students page: $page');

      final url = Uri.parse(
          '${ApiSettings.baseUrl}${ApiSettings.studentsEndpoint}?page=$page');
      final headers = await _getHeaders();

      final response = await http
          .get(
            url,
            headers: headers,
          )
          .timeout(
            Duration(seconds: ApiSettings.connectionTimeout),
            onTimeout: () =>
                throw const ApiException(ApiErrorType.timeout, AppStrings.timeoutError),
          );

      final responseData = _handleResponse(response);

      appLog('Students fetched successfully');
      return responseData;
    });
  }

  // إضافة طالبة جديدة / تحديث تقدمها (الباك بيتعرف عليها بـ d_id + level)
  static Future<Map<String, dynamic>> addStudent({
    required String name,
    required String number,
    required String dId,
  }) async {
    try {
      appLog('Adding new student');

      final url =
          Uri.parse('${ApiSettings.baseUrl}${ApiSettings.addStudentEndpoint}');
      final headers = await _getHeaders();

      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'name': name,
              'number': number,
              'd_id': dId,
            }),
          )
          .timeout(
            Duration(seconds: ApiSettings.connectionTimeout),
            onTimeout: () =>
                throw const ApiException(ApiErrorType.timeout, AppStrings.timeoutError),
          );

      final responseData = _handleResponse(response);

      appLog('Student added successfully');
      return responseData;
    } catch (e) {
      appLog('Error adding student: $e');
      rethrow;
    }
  }

  // جلب بيانات مخطط الحفظ
  static Future<Map<String, dynamic>> getDiagram() async {
    return _withRetry(() async {
      appLog('Fetching memorization diagram data');

      final url =
          Uri.parse('${ApiSettings.baseUrl}${ApiSettings.diagramEndpoint}');
      final headers = await _getHeaders();

      final response = await http
          .get(
            url,
            headers: headers,
          )
          .timeout(
            Duration(seconds: ApiSettings.connectionTimeout),
            onTimeout: () =>
                throw const ApiException(ApiErrorType.timeout, AppStrings.timeoutError),
          );

      final responseData = _handleResponse(response);

      appLog('Diagram data fetched successfully');
      return responseData;
    });
  }

//unread
  static Future<int> getUnreadNotificationsCount() async {
    try {
      return await _withRetry(() async {
        appLog('Fetching unread notifications count');

        final url = Uri.parse(
            '${ApiSettings.baseUrl}${ApiSettings.unreadNotificationsEndpoint}');
        final headers = await _getHeaders();

        final response = await http
            .get(
              url,
              headers: headers,
            )
            .timeout(
              Duration(seconds: ApiSettings.connectionTimeout),
              onTimeout: () =>
                throw const ApiException(ApiErrorType.timeout, AppStrings.timeoutError),
            );

        appLog('Response status (Unread): ${response.statusCode}');

        if (response.statusCode != 200 && response.statusCode != 201) {
          appLog(
              'Error status code for unread notifications: ${response.statusCode}');
          throw ApiException.fromStatus(
              response.statusCode, 'status_${response.statusCode}');
        }

        final dynamic responseData = jsonDecode(response.body);

        if (responseData is List &&
            responseData.isNotEmpty &&
            responseData.first is int) {
          final int count = responseData.first;
          appLog('Unread notifications count processed successfully: $count');
          return count;
        } else {
          appLog(
              'Unexpected response format for unread notifications, returning 0.');
          return 0;
        }
      },
          maxAttempts:
              2); // محاولتين بس هون لإنها أصلاً بتنعاد كل شوي بالـ polling
    } catch (e) {
      appLog('Fatal error fetching unread notifications count: $e');
      return 0;
    }
  }

  static Future<List<dynamic>> getNotifications() async {
    return _withRetry(() async {
      appLog('Fetching all notifications list');

      final url = Uri.parse(
          '${ApiSettings.baseUrl}${ApiSettings.getNotificationsEndpoint}');
      final headers = await _getHeaders();

      final response = await http
          .get(
            url,
            headers: headers,
          )
          .timeout(
            Duration(seconds: ApiSettings.connectionTimeout),
            onTimeout: () =>
                throw const ApiException(ApiErrorType.timeout, AppStrings.timeoutError),
          );

      if (response.statusCode != 200) {
        final responseData = _handleResponse(response);
        throw ApiException.fromStatus(response.statusCode,
            ApiResponseParser.extractErrorMessage(responseData));
      }

      final dynamic responseData = jsonDecode(response.body);

      // ⚠️ ملاحظة خاصة: استجابتك هي مصفوفة داخل مصفوفة: [[..]]
      if (responseData is List &&
          responseData.isNotEmpty &&
          responseData.first is List) {
        appLog('Notifications list fetched successfully');
        return responseData.first; // نرجع القائمة الداخلية
      } else {
        appLog(
            'Unexpected response format for notifications list, returning empty list.');
        return [];
      }
    });
  }

  // 2. جلب تفاصيل إشعار واحد (مُعَدَّل لاستخدام POST)
  static Future<Map<String, dynamic>> getNotificationDetails(
      int notificationId) async {
    try {
      appLog(
          'Fetching notification details for ID: $notificationId using POST method');

      final url = Uri.parse(
          '${ApiSettings.baseUrl}${ApiSettings.getNotificationByIdEndpoint}');
      final headers = await _getHeaders();

      // 1. إنشاء جسم الطلب (Body) لتمرير الـ ID
      final body = jsonEncode({'id': notificationId});

      // 2. استخدام http.post بدلاً من http.get
      final response = await http
          .post(
            url,
            // 3. إضافة Content-Type: application/json للهيدرز
            // هذا يخبر الخادم أننا نرسل بيانات JSON
            headers: {...headers, 'Content-Type': 'application/json'},
            body: body, // 4. تمرير الـ ID في جسم الطلب
          )
          .timeout(
            Duration(seconds: ApiSettings.connectionTimeout),
            onTimeout: () =>
                throw const ApiException(ApiErrorType.timeout, AppStrings.timeoutError),
          );

      // هنا نستخدم _handleResponse لأنه يتوقع استجابة Map
      final responseData = _handleResponse(response);

      appLog('Notification details fetched successfully');
      return responseData;
    } catch (e) {
      appLog('Error fetching notification details: $e');
      rethrow;
    }
  }
}
