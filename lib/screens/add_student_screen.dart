// lib/screens/add_student_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/constants.dart';
import '../services/services.dart';
import '../services/api_exception.dart';
import '../widgets/number_stepper_field.dart';

enum _AddMode { newStudent, updateExisting }

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  _AddStudentScreenState createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  _AddMode _mode = _AddMode.newStudent;

  // متحكمات وضع "طالبة جديدة"
  final _nameController = TextEditingController();
  final _dIdController = TextEditingController();
  final _numberController = TextEditingController(text: '0');

  // متحكمات وضع "تحديث حفظ"
  final _newNumberController = TextEditingController();
  Map<String, dynamic>? _selectedStudent;

  // مفتاح النموذج للتحقق من صحة الحقول
  final _formKey = GlobalKey<FormState>();

  // متغيرات الحالة
  bool _isLoading = false;

  // ✅ قائمة الطالبات "الموجودات" لوضع تحديث الحفظ
  List<dynamic> _existingStudents = [];
  bool _isLoadingExisting = false;
  String? _existingLoadError;

  @override
  void dispose() {
    _nameController.dispose();
    _dIdController.dispose();
    _numberController.dispose();
    _newNumberController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.errorColor : AppColors.successColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ✅ رجوع "ذكي" بعد نجاح الحفظ: بترجع لمين ما فتح هاي الشاشة (سواء كانت
  // الرئيسية أو سجل الطالبات) بدل ما تفرض الانتقال لصفحة طالبات جديدة
  // دايماً — هيك بتشتغل صح بكل الحالات وبدون طبقات إضافية بالتنقّل
  void _returnAfterSuccess() {
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      // حالة نادرة: لو الشاشة انفتحت وما في شي قبلها بالـ stack
      Navigator.pushReplacementNamed(context, AppRoutes.students);
    }
  }

  // ✅ جلب قائمة الطالبات الموجودات (لوضع "تحديث حفظ") — كسول (Lazy)
  Future<void> _loadExistingStudentsIfNeeded() async {
    if (_existingStudents.isNotEmpty || _isLoadingExisting) return;

    setState(() {
      _isLoadingExisting = true;
      _existingLoadError = null;
    });

    try {
      final response = await ApiService.getStudents(page: 1);
      setState(() {
        _existingStudents = response['students'] ?? [];
        _isLoadingExisting = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingExisting = false;
        _existingLoadError = 'تعذّر تحميل قائمة الطالبات، حاولي مرة أخرى';
      });
    }
  }

  // دالة الحفظ الموحّدة (تخدم الوضعين)
  Future<void> _submit() async {
    if (_mode == _AddMode.newStudent) {
      await _submitNewStudent();
    } else {
      await _submitUpdateExisting();
    }
  }

  Future<void> _submitNewStudent() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.addStudent(
        name: _nameController.text.trim(),
        number: _numberController.text.trim(),
        dId: _dIdController.text.trim(),
      );

      if (result['message'] != null) {
        _showMessage('تمت إضافة الطالبة بنجاح');
        _returnAfterSuccess();
      } else {
        _showMessage('فشلت إضافة الطالبة، يرجى المحاولة مرة أخرى',
            isError: true);
      }
    } catch (e) {
      _showMessage(_mapError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitUpdateExisting() async {
    if (_selectedStudent == null) {
      _showMessage('اختاري طالبة من القائمة الأول', isError: true);
      return;
    }

    if (_selectedStudent!['d_id'] == null) {
      _showMessage(
        'هاي الميزة محتاجة تحديث بسيط من الباك اند (d_id) — لسا مش جاهزة',
        isError: true,
      );
      return;
    }

    final int newNumber = int.tryParse(_newNumberController.text) ?? -1;
    if (newNumber < 0) {
      _showMessage('لازم تدخلي رقم صحيح لعدد الأجزاء', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.addStudent(
        name: _selectedStudent!['name'].toString(),
        number: newNumber.toString(),
        dId: _selectedStudent!['d_id'].toString(),
      );

      if (result['message'] != null) {
        _showMessage('تم تحديث حفظ الطالبة بنجاح');
        _returnAfterSuccess();
      } else {
        _showMessage('فشل تحديث الحفظ، يرجى المحاولة مرة أخرى', isError: true);
      }
    } catch (e) {
      _showMessage(_mapError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapError(dynamic e) => userMessageFor(e);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            Text(AppStrings.addStudent),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.paddingMedium),
                _buildModeSelector(),
                const SizedBox(height: AppDimensions.paddingXLarge),
                if (_mode == _AddMode.newStudent)
                  _buildNewStudentForm()
                else
                  _buildUpdateExistingForm(),
                const SizedBox(height: AppDimensions.paddingXLarge),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildModeButton(
            mode: _AddMode.newStudent,
            icon: Icons.person_add,
            label: 'طالبة جديدة',
          ),
        ),
        const SizedBox(width: AppDimensions.paddingMedium),
        Expanded(
          child: _buildModeButton(
            mode: _AddMode.updateExisting,
            icon: Icons.update,
            label: 'تحديث حفظ',
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required _AddMode mode,
    required IconData icon,
    required String label,
  }) {
    final bool selected = _mode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      onTap: () {
        setState(() => _mode = mode);
        if (mode == _AddMode.updateExisting) {
          _loadExistingStudentsIfNeeded();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          border: Border.all(
            color: selected ? AppColors.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color:
                  selected ? AppColors.textOnPrimary : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewStudentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNameField(),
        const SizedBox(height: AppDimensions.paddingMedium),
        _buildDIdField(),
        const SizedBox(height: AppDimensions.paddingMedium),
        NumberStepperField(
          controller: _numberController,
          label: 'عدد الأجزاء (البداية)',
          min: 0,
          validator: (value) {
            if (value == null || value.isEmpty) return 'رقم الجزء مطلوب';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildUpdateExistingForm() {
    if (_isLoadingExisting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_existingLoadError != null) {
      return Center(
        child: Column(
          children: [
            Text(_existingLoadError!,
                style: TextStyle(color: AppColors.errorColor)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadExistingStudentsIfNeeded,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingSmall),
          decoration: BoxDecoration(
            color: AppColors.warningColor.withValues(alpha: 0.15),
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusMedium),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.warningColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'القائمة حالياً بتعرض طالبات اليوم بس',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        Autocomplete<Map<String, dynamic>>(
          displayStringForOption: (s) => s['name'].toString(),
          optionsBuilder: (textEditingValue) {
            final students = _existingStudents.cast<Map<String, dynamic>>();
            if (textEditingValue.text.isEmpty) return students;
            return students.where(
                (s) => s['name'].toString().contains(textEditingValue.text));
          },
          onSelected: (s) {
            setState(() {
              _selectedStudent = s;
              _newNumberController.text = s['number'].toString();
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmit) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'اسم الطالبة',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadiusMedium),
                ),
                filled: true,
                fillColor: AppColors.surfaceColor,
              ),
              validator: (_) {
                if (_selectedStudent == null) return 'اختاري طالبة من القائمة';
                return null;
              },
            );
          },
        ),
        if (_selectedStudent != null) ...[
          const SizedBox(height: AppDimensions.paddingMedium),
          Card(
            color: AppColors.surfaceColor,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الرقم الحالي: ${_selectedStudent!['number']}'),
                  if (_selectedStudent!['d_id'] == null)
                    Text(
                      'بانتظار تحديث الباك',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.errorColor),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          NumberStepperField(
            controller: _newNumberController,
            label: 'عدد الأجزاء الجديد (بيستبدل القديم)',
            min: 0,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final current =
                int.tryParse(_selectedStudent!['number'].toString()) ?? 0;
            final entered = int.tryParse(_newNumberController.text) ?? 0;
            if (entered == current) {
              return Text(
                'بدون تغيير عن الرقم الحالي ($current)',
                style: TextStyle(color: AppColors.textSecondary),
              );
            }
            return Text(
              entered > current
                  ? 'يصبح عدد أجزائها: $entered (بدل $current)'
                  : 'تنبيه: بيصير عدد أجزائها $entered — أقل من الرقم الحالي ($current)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: entered >= current
                    ? AppColors.primaryColor
                    : AppColors.warningColor,
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      keyboardType: TextInputType.text,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: 'اسم الطالبة',
        prefixIcon: const Icon(Icons.person),
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
      validator: (value) {
        if (value == null || value.isEmpty) return 'اسم الطالبة مطلوب';
        if (value.length < 2) return 'يجب أن يكون اسم الطالبة 2 أحرف على الأقل';
        return null;
      },
    );
  }

  Widget _buildDIdField() {
    return TextFormField(
      controller: _dIdController,
      keyboardType: TextInputType.number,
      textDirection: TextDirection.ltr,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: 'رقم الطالبة الثابت (بالسجل)',
        prefixIcon: const Icon(Icons.badge),
        helperText:
            'رقم فريد لكل طالبة ما بيتكرر — إذا كرّرتيه غلط بيتحدّث حفظ طالبة تانية بدل ما تنضاف وحدة جديدة',
        helperMaxLines: 2,
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
      validator: (value) {
        if (value == null || value.isEmpty) return 'رقم الطالبة الثابت مطلوب';
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusMedium),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.textOnPrimary,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _mode == _AddMode.newStudent ? 'إضافة' : 'تحديث الحفظ',
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
