// lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:quran/model/notification_model.dart';
import '../constants/constants.dart';
import '../services/services.dart';
import '../widgets/app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // جلب قائمة الإشعارات
  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.getNotifications();

      // تحويل الاستجابة (List<dynamic>) إلى List<NotificationModel>
      final List<NotificationModel> loadedNotifications = response
          .map((json) =>
              NotificationModel.fromJsonList(json as Map<String, dynamic>))
          .toList();

      setState(() {
        _notifications = loadedNotifications;
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // دالة لمعالجة الضغط على الإشعار
  Future<void> _handleNotificationTap(int notificationId) async {
    // الانتقال لصفحة التفاصيل وتوقع نتيجة (هل تم تحديث شيء؟)
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.notificationDetails,
      arguments: notificationId, // تمرير الـ ID كـ arguments
    );

    // إذا عادت قيمة (True)، هذا يعني أن المستخدم أغلق شاشة التفاصيل، نقوم بالتحديث.
    if (result == true) {
      _fetchNotifications();
    }
  }

  // تحديث القائمة بالسحب للأسفل
  Future<void> _refresh() async {
    await _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.notifications,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'خطأ في جلب الإشعارات: $_errorMessage',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد إشعارات حالياً',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('تحديث'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusMedium),
            ),
            child: ListTile(
              onTap: () => _handleNotificationTap(notification.id),
              leading: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.2),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadiusSmall),
                ),
                child: Icon(
                  Icons.message, // أيقونة افتراضية
                  color: AppColors.primaryColor,
                ),
              ),
              title: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'ID: ${notification.id}', // يمكن عرض أي تفاصيل أخرى هنا
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}
