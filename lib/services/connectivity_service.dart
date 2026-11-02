import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  /// فحص فوري: في اتصال بالإنترنت هلق ولا لأ
  static Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _hasConnection(result);
    } catch (e) {
      // لو صار خطأ بالفحص نفسه، نفترض إنه في اتصال حتى ما نمنع المستخدمة
      // من المحاولة عادي (الطلب نفسه رح يفشل ويعطي رسالة واضحة لو فعلاً مقطوعة)
      return true;
    }
  }

  /// مراقبة مستمرة لتغيّر حالة الاتصال (true = متصل، false = مقطوع)
  static Stream<bool> get onStatusChange {
    return _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  static bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}
