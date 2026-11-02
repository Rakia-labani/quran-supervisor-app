// lib/widgets/number_stepper_field.dart
//
// حقل رقمي بأسهم +/- لزيادة/إنقاص القيمة بضغطة، بدل الكتابة اليدوية بس.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/constants.dart';

class NumberStepperField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final int min;
  final int? max;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const NumberStepperField({
    super.key,
    required this.controller,
    required this.label,
    this.min = 0,
    this.max,
    this.validator,
    this.onChanged,
  });

  @override
  State<NumberStepperField> createState() => _NumberStepperFieldState();
}

class _NumberStepperFieldState extends State<NumberStepperField> {
  // ✅ FocusNode خاص فينا حتى نحدد كل النص لما الحقل ياخد التركيز — هيك
  // أول رقم تكتبيه بيستبدل القيمة الحالية (متل الصفر الافتراضي) بدل ما
  // يضاف جنبها ("0" + "7" = "07")
  final FocusNode _focusNode = FocusNode();

  int get _value => int.tryParse(widget.controller.text) ?? widget.min;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.controller.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _changeBy(int delta) {
    int newValue = _value + delta;
    if (newValue < widget.min) newValue = widget.min;
    if (widget.max != null && newValue > widget.max!) newValue = widget.max!;
    setState(() {
      widget.controller.text = newValue.toString();
    });
    widget.onChanged?.call(widget.controller.text);
  }

  // ✅ شبكة أمان إضافية: حتى لو تحديد النص عند التركيز ما اشتغل لسبب ما
  // (مثلاً كيبورد معيّن أو منصة معيّنة)، هاي الدالة بتشيل أي صفر زايد
  // بأول الرقم فور الكتابة ("07" بترجع "7" مباشرة)
  void _handleChanged(String value) {
    String v = value;
    if (v.length > 1 && v.startsWith('0')) {
      v = v.replaceFirst(RegExp(r'^0+'), '');
      if (v.isEmpty) v = '0';
      widget.controller.value = TextEditingValue(
        text: v,
        selection: TextSelection.collapsed(offset: v.length),
      );
    }
    widget.onChanged?.call(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: _handleChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.primaryColor,
          onPressed: () => _changeBy(-1),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.primaryColor,
          onPressed: () => _changeBy(1),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
        filled: true,
        fillColor: AppColors.surfaceColor,
      ),
      validator: widget.validator,
    );
  }
}
