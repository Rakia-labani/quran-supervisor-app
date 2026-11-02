import 'package:flutter/foundation.dart';

/// Debug-only logger. Nothing is printed in release builds.
void appLog(String message) {
  if (kDebugMode) debugPrint(message);
}
