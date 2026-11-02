// lib/services/local_cache.dart
//
// كاش محلي بسيط (باستخدام shared_preferences الموجودة أصلاً بالمشروع)
// لآخر استجابة ناجحة من أي طلب، حتى تنعرض فوراً لما نفتح الشاشة (قبل
// وصول رد السيرفر) أو حتى لو ما في نت أصلاً — نمط Stale-While-Revalidate.

import '../utils/app_logger.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCache {
  static const String _timestampSuffix = '_cached_at';

  /// حفظ استجابة (Map) بمفتاح معيّن مع وقت الحفظ
  static Future<void> save(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
      await prefs.setString(
        '$key$_timestampSuffix',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      appLog('LocalCache save error ($key): $e');
    }
  }

  /// قراءة آخر استجابة محفوظة بهاد المفتاح (null لو ما في شي محفوظ)
  static Future<Map<String, dynamic>?> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      appLog('LocalCache read error ($key): $e');
      return null;
    }
  }

  /// وقت آخر حفظ لهاد المفتاح (لعرض "آخر تحديث: ...")
  static Future<DateTime?> lastUpdated(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$key$_timestampSuffix');
      if (raw == null) return null;
      return DateTime.tryParse(raw);
    } catch (e) {
      return null;
    }
  }
}
