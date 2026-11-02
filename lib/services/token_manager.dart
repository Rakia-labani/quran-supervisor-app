// lib/services/token_manager.dart

import '../utils/app_logger.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تخزين التوكن والدور بشكل مشفّر (Android Keystore) بدل SharedPreferences العادي.
class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'user_role';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // حفظ التوكن
  static Future<void> saveToken(String token, String role) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _roleKey, value: role);
      appLog('Token saved successfully');
    } catch (e) {
      appLog('Error saving token: $e');
    }
  }

  // الحصول على التوكن
  static Future<String?> getToken() async {
    try {
      await _migrateLegacyPrefs();
      final token = await _storage.read(key: _tokenKey);
      appLog('Token retrieved: ${token != null ? 'Yes' : 'No'}');
      return token;
    } catch (e) {
      appLog('Error retrieving token: $e');
      return null;
    }
  }

  // الحصول على دور المستخدم
  static Future<String?> getRole() async {
    try {
      await _migrateLegacyPrefs();
      final role = await _storage.read(key: _roleKey);
      appLog('Role retrieved: ${role ?? 'No role'}');
      return role;
    } catch (e) {
      appLog('Error retrieving role: $e');
      return null;
    }
  }

  // حذف التوكن (تسجيل الخروج)
  static Future<void> clearToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _roleKey);
      await _removeLegacyPrefs();
      appLog('Token cleared successfully');
    } catch (e) {
      appLog('Error clearing token: $e');
    }
  }

  // التحقق من وجود توكن صالح
  static Future<bool> hasValidToken() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      appLog('Error checking token validity: $e');
      return false;
    }
  }

  // ✅ ترحيل لمرة وحدة: لو المستخدمة كانت مسجّلة بالنسخة القديمة (SharedPreferences)
  // ننقل التوكن للتخزين المشفّر ونمسحه من القديم، عشان ما تضطر تسجل دخول من جديد
  static Future<void> _migrateLegacyPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString(_tokenKey);
      if (legacyToken == null) return;

      final legacyRole = prefs.getString(_roleKey);
      await _storage.write(key: _tokenKey, value: legacyToken);
      if (legacyRole != null) {
        await _storage.write(key: _roleKey, value: legacyRole);
      }
      await _removeLegacyPrefs();
      appLog('Legacy token migrated to secure storage');
    } catch (e) {
      appLog('Legacy token migration failed: $e');
    }
  }

  static Future<void> _removeLegacyPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
  }
}
