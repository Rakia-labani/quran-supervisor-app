// lib/widgets/offline_banner.dart

import 'package:flutter/material.dart';
import '../constants/constants.dart';

class OfflineBanner extends StatelessWidget {
  final String? message;

  const OfflineBanner({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warningColor,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              message ??
                  'غير متصلة بالإنترنت — البيانات المعروضة آخر نسخة محفوظة',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
