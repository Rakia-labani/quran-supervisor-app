// lib/constants/constants.dart

import 'package:flutter/material.dart';

class AppColors {
  // الألوان الرئيسية المستوحاة من الصورة (نفس الألوان الأصلية)
  static const Color primaryColor = Color(0xFF9C88B3); // بنفسجي هادئ
  static const Color secondaryColor = Color(0xFFA4D7C5); // أخضر فاتح
  static const Color accentColor = Color(0xFFE8D5F2); // بنفسجي فاتح جداً
  static const Color backgroundColor = Color(0xFFF8F5F2); // خلفية كريمية
  static const Color surfaceColor = Color(0xFFFFFFFF); // أبيض للبطاقات

  // ألوان النصوص
  static const Color textPrimary =
      Color(0xFF4A4A4A); // رمادي داكن للنصوص الرئيسية
  static const Color textSecondary =
      Color(0xFF757575); // رمادي متوسط للنصوص الثانوية
  static const Color textOnPrimary =
      Color(0xFFFFFFFF); // أبيض للنصوص على الخلفية الملونة

  // ألوان الحالات
  static const Color errorColor = Color(0xFFE57373); // أحمر فاتح للأخطاء
  static const Color successColor = Color(0xFF81C784); // أخضر فاتح للنجاح
  static const Color warningColor = Color(0xFFFFB74D); // برتقالي فاتح للتحذيرات
}

class AppStrings {
  static const String appName = 'مشرفة حفظ القرآن';
  static const String loginTitle = 'تسجيل دخول المشرفة';
  static const String phoneNumber = 'رقم الهاتف';
  static const String password = 'كلمة المرور';
  static const String loginButton = 'دخول';
  static const String welcomeMessage = 'مرحباً بكِ في تطبيق مشرفة حفظ القرآن';

  static const String loginSubtitle = 'سجلي دخولكِ لإدارة وتتبع حفظ الطالبات';
  static const String logout = 'تسجيل الخروج';
  static const String logoutConfirmation = 'هل أنتِ متأكدة من تسجيل الخروج؟';
  static const String yes = 'نعم';
  static const String no = 'لا';

  // نصوص إضافية للمشرفة
  static const String students = 'سجل الطالبات';
  static const String addStudent = 'إضافة طالبة';
  static const String notifications = 'الإشعارات';
  static const String studentName = 'اسم الطالبة';
  static const String studentClass = 'الصف';
  static const String save = 'حفظ';
  static const String memorizationRecord = 'مخطط الحفظ';
  static const String addRecord = 'إضافة سجل حفظ';

  // نصوص الإشعارات
  static const String noNotifications = 'لا توجد إشعارات حالياً';
  static const String newMemorization = 'حفظ جديد';
  static const String studentCompleted = 'أكملت الطالبة حفظ';
  static const String reminder = 'تذكير';
  static const String systemUpdate = 'تحديث النظام';

  // رسائل الخطأ
  static const String phoneRequired = 'رقم الهاتف مطلوب';
  static const String passwordRequired = 'كلمة المرور مطلوبة';
  static const String invalidPhone = 'رقم الهاتف غير صحيح';
  static const String invalidPassword =
      'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
  static const String loginFailed = 'فشل تسجيل الدخول، يرجى التحقق من بياناتك';
  static const String networkError =
      'خطأ في الاتصال بالإنترنت، يرجى التحقق من اتصالك';
  static const String serverError =
      'خطأ في الخادم، يرجى المحاولة مرة أخرى لاحقاً';
  static const String timeoutError =
      'انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى';
  static const String unauthorizedError =
      'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى';
  static const String unknownError =
      'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';

  // رسائل النجاح
  static const String loginSuccess = 'تم تسجيل الدخول بنجاح';
  static const String logoutSuccess = 'تم تسجيل الخروج بنجاح';

  // رسائل المعلومات
  static const String loading = 'جاري التحميل...';
  static const String loggingIn = 'جاري تسجيل الدخول...';

  // رسائل الخطأ الخاصة بالمطور
  static const String devLoginError = 'DEV: خطأ في تسجيل الدخول';
  static const String devTokenError = 'DEV: خطأ في إدارة التوكن';
  static const String devNetworkError = 'DEV: خطأ في الشبكة';

  // رسائل الخطأ
  static const String studentAdded = 'تمت إضافة الطالبة بنجاح';
  static const String studentDeleted = 'تم حذف الطالبة بنجاح';
  static const String recordAdded = 'تمت إضافة سجل الحفظ بنجاح';
  static const String recordDeleted = 'تم حذف سجل الحفظ بنجاح';
}

class AppDimensions {
  // أبعاد التطبيق
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  static const double fontSizeSmall = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 24.0;
  static const double fontSizeXXLarge = 32.0;
  static const double fontSizeExtraLarge = 24.0;
}

class AppRoutes {
  // مسارات التطبيق
  static const String login = '/login';
  static const String home = '/home';
  static const String students = '/students';
  static const String addStudent = '/add_student';
  static const String studentDetails = '/student_details';
  static const String addRecord = '/add_record';
  static const String diagram = '/diagram';
  static const String notifications = '/notifications';
  static const String notificationDetails = '/notification_details';
}

class ApiSettings {
  static const String baseUrl =
      'https://api.example.com'; // TODO: set your backend URL

  // Endpoints
  static const String loginEndpoint = '/api/login';
  static const String logoutEndpoint = '/api/logout';
  static const String userEndpoint = '/api/user';
  static const String studentsEndpoint = '/api/levelStudents';
  static const String addStudentEndpoint = '/api/store';
  static const String diagramEndpoint = '/api/diagram';
  static const String unreadNotificationsEndpoint = '/api/unread';
  static const String getNotificationsEndpoint = '/api/getNotifications';
  static const String getNotificationByIdEndpoint = '/api/getNotificationById';

  // مهلة الاتصال بالثواني
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;
}
