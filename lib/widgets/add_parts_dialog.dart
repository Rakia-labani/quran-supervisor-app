// lib/widgets/add_parts_dialog.dart

import 'package:flutter/material.dart';

import '../constants/constants.dart';
import '../services/api_exception.dart';
import '../services/services.dart';
import 'number_stepper_field.dart';

/// يعرض نافذة إضافة أجزاء لطالبة موجودة. يرجّع true إذا تم التحديث بنجاح.
Future<bool?> showAddPartsDialog(
  BuildContext context,
  Map<String, dynamic> student,
) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AddPartsDialog(student: student),
  );
}

class AddPartsDialog extends StatefulWidget {
  final Map<String, dynamic> student;

  const AddPartsDialog({super.key, required this.student});

  @override
  State<AddPartsDialog> createState() => _AddPartsDialogState();
}

class _AddPartsDialogState extends State<AddPartsDialog> {
  final TextEditingController _partsController = TextEditingController(
    text: '1',
  );
  bool _isSubmitting = false;

  int get _currentNumber =>
      int.tryParse(widget.student['number'].toString()) ?? 0;

  // TODO: يتطلب أن يرجّع الـ API الحقل d_id مع بيانات الطالبات.
  // لحد ما ينضاف، الزر معطّل.
  bool get _canSubmit => widget.student['d_id'] != null;

  @override
  void dispose() {
    _partsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final int partsToAdd = int.tryParse(_partsController.text) ?? 0;
    if (partsToAdd <= 0) return;

    setState(() => _isSubmitting = true);
    try {
      await ApiService.addStudent(
        name: widget.student['name'].toString(),
        number: (_currentNumber + partsToAdd).toString(),
        dId: widget.student['d_id'].toString(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessageFor(e)),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int add = int.tryParse(_partsController.text) ?? 0;

    return AlertDialog(
      title: Text('إضافة أجزاء — ${widget.student['name']}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الرقم الحالي: $_currentNumber'),
          const SizedBox(height: AppDimensions.paddingMedium),
          NumberStepperField(
            controller: _partsController,
            label: 'أجزاء تُضاف',
            min: 1,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text(
            'الإجمالي الجديد: ${_currentNumber + add}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          if (!_canSubmit)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'هذه الميزة غير متاحة حالياً',
                style: TextStyle(fontSize: 11, color: AppColors.errorColor),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: (_isSubmitting || !_canSubmit) ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('تحديث'),
        ),
      ],
    );
  }
}
