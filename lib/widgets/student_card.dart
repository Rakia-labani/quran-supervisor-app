// lib/widgets/student_card.dart

import 'package:flutter/material.dart';

import '../constants/constants.dart';

/// بطاقة طالبة في قائمة الطالبات، مع زر لإضافة أجزاء بسرعة.
class StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onAddParts;

  const StudentCard({
    super.key,
    required this.student,
    required this.onAddParts,
  });

  @override
  Widget build(BuildContext context) {
    final String name = student['name'].toString();
    // حماية: لو الاسم فاضي ما نعمل substring على نص فاضي
    final String initial = name.isEmpty
        ? '?'
        : name.substring(0, 1).toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppDimensions.paddingMedium),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryColor,
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: AppDimensions.fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'عدد الأجزاء: ${student['number']}',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeMedium,
            color: AppColors.textSecondary,
          ),
        ),
        // ✅ إضافة أجزاء سريعة مباشرة من سجل الطالبات
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.primaryColor,
          tooltip: 'إضافة أجزاء',
          onPressed: onAddParts,
        ),
      ),
    );
  }
}
