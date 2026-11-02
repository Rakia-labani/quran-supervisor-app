import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../widgets/app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.appName,
        actions: [
          // أيقونة تسجيل الخروج
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutConfirmation(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ترحيب
            Text(
              'نُّورٌ عَلَىٰ نُورٍۢ',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeXLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'يمكنكِ إدارة الطالبات وتتبع حفظهن للقرآن الكريم',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),

            // بطاقات الإجراءات
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: AppDimensions.paddingMedium,
                mainAxisSpacing: AppDimensions.paddingMedium,
                children: [
                  // بطاقة الطالبات
                  _buildActionCard(
                    context,
                    title: AppStrings.students,
                    icon: Icons.people,
                    color: AppColors.secondaryColor, // نفس اللون الأصلي
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.students);
                    },
                  ),

                  // بطاقة الإشعارات
                  _buildActionCard(
                    context,
                    title: AppStrings.notifications,
                    icon: Icons.notifications,
                    color: AppColors.warningColor,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.notifications);
                    },
                  ),

                  // بطاقة سجلات الحفظ
                  _buildActionCard(
                    context,
                    title: AppStrings.memorizationRecord,
                    icon: Icons.bar_chart,
                    color: AppColors.primaryColor, // نفس اللون الأصلي
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.diagram);
                    },
                  ),

                  // بطاقة إضافة طالبة
                  _buildActionCard(
                    context,
                    title: AppStrings.addStudent,
                    icon: Icons.person_add,
                    color: AppColors.successColor,
                    onTap: () async {
                      // ✅ ننتظر نتيجة شاشة الإضافة. لو نجحت (رجعت true)،
                      // منكمل مباشرة عالسجل حتى تتأكدي إنها انضافت، وبنفس
                      // الوقت ضغطة رجوع وحدة من السجل بترجعك هون للرئيسية
                      final added = await Navigator.pushNamed(
                        context,
                        AppRoutes.addStudent,
                      );
                      if (added == true && context.mounted) {
                        Navigator.pushNamed(context, AppRoutes.students);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة إظهار تأكيد تسجيل الخروج
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppStrings.logout),
          content: Text(AppStrings.logoutConfirmation),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // إغلاق مربع الحوار
              },
              child: Text(AppStrings.no),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // إغلاق مربع الحوار
                Navigator.pushReplacementNamed(
                    context, AppRoutes.login); // الانتقال إلى صفحة تسجيل الدخول
              },
              child: Text(AppStrings.yes),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadiusLarge),
                ),
                child: Icon(
                  icon,
                  size: AppDimensions.iconSizeLarge,
                  color: color,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
