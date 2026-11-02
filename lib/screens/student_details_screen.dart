// lib/screens/student_details_screen.dart

import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../widgets/app_bar.dart';

// شاشة تفاصيل طالبة واحدة — بتفتح لما تضغطي على اسم طالبة
// من جدول/قائمة "تفاصيل الحفظ" بشاشة المخطط
class StudentDetailsScreen extends StatelessWidget {
  const StudentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final Map<String, dynamic> student =
        args is Map<String, dynamic> ? args : <String, dynamic>{};

    final String name = (student['name'] ?? '—').toString();
    final int number = student['number'] is int
        ? student['number'] as int
        : int.tryParse(student['number']?.toString() ?? '') ?? 0;

    // نفترض أن الحفظ الكامل هو 30 جزء (عدد أجزاء القرآن الكريم)
    final double progress = (number / 30).clamp(0, 1).toDouble();
    final int percent = (progress * 100).round();
    final bool isComplete = number >= 30;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'تفاصيل الطالبة',
        showNotifications: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryColor,
              child: Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '؟',
                style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              name,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeXLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusMedium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'عدد الأجزاء المنجزة',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        // ✅ Directionality.ltr هون تحديداً حتى الرقمين
                        // يطلعوا بترتيبهم الصحيح "9/30" وما ينعكسوا
                        // بسبب اتجاه الصفحة العربي (RTL)
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            '$number/30',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade200,
                        color: isComplete
                            ? AppColors.successColor
                            : AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$percent٪ من الحفظ الكامل',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    if (isComplete) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.emoji_events,
                              color: AppColors.successColor),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'أتمّت حفظ القرآن كاملاً 🎉',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.successColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
