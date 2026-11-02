import 'package:flutter/material.dart';
import 'package:quran/model/notification_model.dart';
import '../constants/constants.dart';
import '../services/services.dart';
import '../widgets/app_bar.dart';

class NotificationDetailsScreen extends StatefulWidget {
  final int notificationId;

  const NotificationDetailsScreen({super.key, required this.notificationId});

  @override
  _NotificationDetailsScreenState createState() =>
      _NotificationDetailsScreenState();
}

class _NotificationDetailsScreenState extends State<NotificationDetailsScreen> {
  NotificationModel? _notification;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchNotificationDetails();
  }

  Future<void> _fetchNotificationDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response =
          await ApiService.getNotificationDetails(widget.notificationId);

      setState(() {
        _notification = NotificationModel.fromJsonDetails(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e
            .toString()
            .replaceFirst('Exception: ', ''); // إزالة كلمة Exception:
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'تفاصيل الإشعار',
        showNotifications: false, // لا نريد جرس الإشعارات هنا
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('خطأ: $_errorMessage', textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.paddingMedium),
            ElevatedButton(
              onPressed: _fetchNotificationDetails,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_notification == null) {
      return const Center(child: Text('لم يتم العثور على الإشعار.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // زر الإغلاق (الرجوع)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      Navigator.pop(context, true), // نرسل true لتحديث القائمة
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              Text(
                _notification!.title,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeExtraLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const Divider(height: 24),

              Text(
                'المحتوى:',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
              Text(
                _notification!.content!,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeMedium,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingLarge),

              Text(
                'تاريخ الإنشاء:',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
              Text(
                _notification!.createdAt != null
                    ? _formatDate(_notification!.createdAt!)
                    : 'غير متاح',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeMedium,
                  color: AppColors.textSecondary,
                ),
              ),

              // حالة القراءة
              const SizedBox(height: AppDimensions.paddingLarge),
              Row(
                children: [
                  Icon(
                    _notification!.isRead!
                        ? Icons.check_circle
                        : Icons.circle_notifications,
                    color: _notification!.isRead!
                        ? AppColors.successColor
                        : AppColors.warningColor,
                  ),
                  const SizedBox(width: AppDimensions.paddingSmall),
                  Text(
                    _notification!.isRead! ? 'مقروء' : 'غير مقروء',
                    style: TextStyle(
                      color: _notification!.isRead!
                          ? AppColors.successColor
                          : AppColors.warningColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // تنسيق بسيط للوقت والتاريخ
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
