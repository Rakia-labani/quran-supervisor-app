// lib/widgets/app_bar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // استيراد Provider
import '../constants/constants.dart';
import '../providers/notification_provider.dart'; // استيراد المزود

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showNotifications;
  final VoidCallback? onNotificationTap;
  // تم إزالة hasNotifications ليعتمد على الـ Provider

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showNotifications = true,
    this.onNotificationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    List<Widget> defaultActions = [];

    // إضافة جرس الإشعارات إذا كان مطلوباً
    if (showNotifications) {
      // استخدام Consumer للاستماع إلى التغييرات في NotificationProvider
      defaultActions.add(
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            final int count = notificationProvider.unreadCount;
            final bool hasUnread = count > 0;

            return IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        // عرض العدد الفعلي بدلاً من النقطة الثابتة
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          // لعرض العدد 9+ إذا كان أكبر من 9، أو العدد نفسه
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: onNotificationTap ??
                  () {
                    // تصفير العداد محلياً عند الضغط
                    notificationProvider.markAsRead();
                    // الانتقال لصفحة الإشعارات
                    Navigator.pushNamed(context, AppRoutes.notifications);
                  },
            );
          },
        ),
      );
    }

    // إضافة أي إجراءات إضافية
    if (actions != null) {
      defaultActions.addAll(actions!);
    }

    return AppBar(
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/quran_logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Text(title),
        ],
      ),
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 0,
      actions: defaultActions,
    );
  }
}
