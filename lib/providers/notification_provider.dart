// lib/providers/notification_provider.dart
//
// ✅ Polling ذكي بدل الفاصل الثابت (10 ثواني دائماً):
// - يبطّئ تدريجياً لما ما يصير تغيير بالعدد (يوفّر بطارية ونت)
// - يرجع للفاصل السريع فوراً لما يصير تغيير حقيقي
// - يتوقف كلياً لما التطبيق بالخلفية، ويرجع يشتغل فوراً لما يرجع للواجهة
// - يتجاهل الطلب أصلاً لو ما في نت (بدل ما ينتظر timeout كامل ويفشل)
// - يمنع تراكم طلبات متزامنة (guard على _isFetching)

import '../utils/app_logger.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/services.dart';
import '../services/token_manager.dart';
import '../services/connectivity_service.dart';

class NotificationProvider extends ChangeNotifier with WidgetsBindingObserver {
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  Timer? _timer;
  bool _isFetching = false;
  bool _isAppActive = true;

  static const int _baseIntervalSeconds = 10;
  static const int _maxIntervalSeconds = 40;
  static const int _stepSeconds = 5;
  int _currentIntervalSeconds = _baseIntervalSeconds;

  NotificationProvider() {
    WidgetsBinding.instance.addObserver(this);
    _scheduleNext(immediate: true);
  }

  // ✅ مراقبة دورة حياة التطبيق (خلفية/واجهة)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppActive = true;
      _currentIntervalSeconds = _baseIntervalSeconds; // نرجع نراقب بسرعة فوراً
      _scheduleNext(immediate: true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _isAppActive = false;
      _timer?.cancel();
    }
  }

  // جلب وتحديث العدد
  Future<void> fetchUnreadCount() async {
    if (_isFetching || !_isAppActive) return;

    final bool hasToken = await TokenManager.hasValidToken();
    if (!hasToken) {
      if (_unreadCount != 0) {
        _unreadCount = 0;
        notifyListeners();
      }
      _scheduleNext();
      return;
    }

    // ✅ ما منعمل طلب شبكة أصلاً لو ما في نت — بيوفر بطارية ونت وبيتجنب
    // انتظار الـ timeout بالفاضي
    final bool connected = await ConnectivityService.isConnected();
    if (!connected) {
      _scheduleNext();
      return;
    }

    _isFetching = true;
    try {
      final int newCount = await ApiService.getUnreadNotificationsCount();

      if (newCount != _unreadCount) {
        _unreadCount = newCount;
        notifyListeners();
        // ✅ في تغيير فعلي — نرجع للفاصل السريع لإنه في نشاط هلق
        _currentIntervalSeconds = _baseIntervalSeconds;
      } else {
        // ✅ ما في تغيير — نبطّئ تدريجياً (خطوة 5 ثواني لحد سقف 40 ثانية)
        _currentIntervalSeconds =
            (_currentIntervalSeconds + _stepSeconds).clamp(
          _baseIntervalSeconds,
          _maxIntervalSeconds,
        );
      }
    } catch (e) {
      appLog('Polling error: $e');
    } finally {
      _isFetching = false;
      _scheduleNext();
    }
  }

  // جدولة الجلب الجاي (أو تنفيذه فوراً)
  void _scheduleNext({bool immediate = false}) {
    _timer?.cancel();
    if (!_isAppActive) return;

    if (immediate) {
      fetchUnreadCount();
      return;
    }

    _timer = Timer(
      Duration(seconds: _currentIntervalSeconds),
      fetchUnreadCount,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // عند الدخول إلى شاشة الإشعارات (لجعل العدد 0)
  void markAsRead() {
    _unreadCount = 0;
    notifyListeners();
  }
}
