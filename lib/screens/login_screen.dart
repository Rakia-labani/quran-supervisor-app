import '../utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/constants.dart';
import '../services/services.dart';
import '../services/api_exception.dart';
import '../widgets/app_bar.dart';
import '../utils/size_config.dart'; // ✅ إضافة الاستيراد الجديد

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.login(
        _phoneController.text.trim(),
        _passwordController.text,
      );

      if (result['token'] != null) {
        _showMessage(AppStrings.loginSuccess);
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        _showMessage(AppStrings.loginFailed, isError: true);
      }
    } catch (e) {
      appLog('${AppStrings.devLoginError}: $e');
      final String errorMessage = _loginErrorMessage(e);

      _showMessage(errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // رسالة الخطأ المناسبة لشاشة تسجيل الدخول
  String _loginErrorMessage(Object e) {
    final error = ApiException.from(e);
    final msg = error.message;

    // رسائل الخادم الخاصة بالحساب بتنعرض كما هي
    if (msg.contains('بيانات الاعتماد غير صحيحة')) {
      return 'رقم الهاتف أو كلمة المرور غير صحيحة';
    }
    if (msg.contains('حسابك') || msg.contains('محاولات تسجيل دخول كثيرة')) {
      return msg;
    }
    return userMessageFor(error);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context); // ✅ تفعيل المقاسات حسب الجهاز

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: const CustomAppBar(
        title: AppStrings.appName,
        showNotifications: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.blockWidth * 5), // ✅ بدل الثابت
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: SizeConfig.blockHeight * 5), // ✅

                _buildLogo(),

                SizedBox(height: SizeConfig.blockHeight * 5), // ✅

                Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: SizeConfig.blockWidth * 6, // ✅
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),

                SizedBox(height: SizeConfig.blockHeight * 1.5),

                Text(
                  AppStrings.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: SizeConfig.blockWidth * 3.5, // ✅
                    color: AppColors.textSecondary,
                  ),
                ),

                SizedBox(height: SizeConfig.blockHeight * 5), // ✅

                _buildPhoneField(),

                SizedBox(height: SizeConfig.blockHeight * 2), // ✅

                _buildPasswordField(),

                SizedBox(height: SizeConfig.blockHeight * 4), // ✅

                _buildLoginButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: SizeConfig.blockWidth * 30, // ✅
      height: SizeConfig.blockWidth * 30, // ✅
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SizeConfig.blockWidth * 15), // ✅
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SizeConfig.blockWidth * 15), // ✅
        child: Image.asset(
          'assets/images/quran_logo.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textDirection: TextDirection.ltr,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: AppStrings.phoneNumber,
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.blockWidth * 2.5), // ✅
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.blockWidth * 2.5), // ✅
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
        filled: true,
        fillColor: AppColors.surfaceColor,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'رقم الهاتف مطلوب';
        if (value.length < 10) return AppStrings.invalidPhone;
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: AppStrings.password,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.blockWidth * 2.5), // ✅
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SizeConfig.blockWidth * 2.5), // ✅
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
        filled: true,
        fillColor: AppColors.surfaceColor,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
        if (value.length < 8) return 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: SizeConfig.blockHeight * 7, // ✅ بدل 50
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(SizeConfig.blockWidth * 2.5), // ✅
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? SizedBox(
                width: SizeConfig.blockWidth * 5,
                height: SizeConfig.blockWidth * 5,
                child: const CircularProgressIndicator(
                  color: AppColors.textOnPrimary,
                  strokeWidth: 2,
                ),
              )
            : Text(
                AppStrings.loginButton,
                style: TextStyle(
                  fontSize: SizeConfig.blockWidth * 4, // ✅
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
