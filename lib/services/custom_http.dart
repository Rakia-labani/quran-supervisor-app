// lib/services/custom_http.dart
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;

/// دالة لإنشاء عميل HTTP يتجاهل أخطاء الشهادات (SSL)
/// **ملاحظة هامة:** استخدم هذا للاختبار فقط! لا تستخدمه في التطبيق النهائي.
http.Client createInsecureHttpClient() {
  final ioc = HttpClient();
  // هذا السطر هو المسؤول عن قبول أي شهادة SSL، حتى لو كانت غير موثوقة
  ioc.badCertificateCallback =
      (X509Certificate cert, String host, int port) => true;
  return IOClient(ioc);
}
