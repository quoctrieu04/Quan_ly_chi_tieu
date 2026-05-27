import 'package:chitieu/core/theme/app_colors.dart';
import 'package:chitieu/utils/safe_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _f = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  Future<void> _openRegister() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );

    if (!mounted || result == null) return;

    _email.text = (result['email']?.toString() ?? '').trim();
    _pass.text = result['password']?.toString() ?? '';
    context.read<AuthProvider>().clearLoginErrors();
    _emailFocus.requestFocus();
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // Màu teal chủ đạo giống hình
    const primaryColor = AppColors.primary;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _f,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Icon tròn
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 24),
                // Tiêu đề
                const Text(
                  'Chào mừng trở lại!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đăng nhập để tiếp tục quản lý chi tiêu',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 48),

                // Input Email
                TextFormField(
                  controller: _email,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (auth.emailError != null || auth.error != null) {
                      context.read<AuthProvider>().clearLoginErrors();
                    }
                  },
                  onFieldSubmitted: (_) => _passFocus.requestFocus(),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    errorText: auth.emailError,
                    hintStyle: const TextStyle(color: AppColors.textSub),
                    prefixIcon:
                        const Icon(Icons.email_rounded, color: primaryColor),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.border, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: primaryColor, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Vui lòng nhập email';
                    if (!value.contains('@')) return 'Email không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Input Mật khẩu
                TextFormField(
                  controller: _pass,
                  focusNode: _passFocus,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (auth.passwordError != null || auth.error != null) {
                      context.read<AuthProvider>().clearLoginErrors();
                    }
                  },
                  onFieldSubmitted: (_) async {
                    if (auth.loading) return;
                    if (!_f.currentState!.validate()) return;
                    final ok = await context
                        .read<AuthProvider>()
                        .login(_email.text.trim(), _pass.text);
                    if (!mounted) return;
                    if (ok) {
                      showAppSnackBar(context, 'Đăng nhập thành công',
                          icon: Icons.check_circle_rounded);
                      return;
                    }
                    final state = context.read<AuthProvider>();
                    if (state.emailError != null) {
                      _emailFocus.requestFocus();
                    } else {
                      _passFocus.requestFocus();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Mật khẩu',
                    errorText: auth.passwordError,
                    hintStyle: const TextStyle(color: AppColors.textSub),
                    prefixIcon:
                        const Icon(Icons.lock_rounded, color: primaryColor),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.border, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: primaryColor, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mật khẩu phải từ 6 ký tự'
                      : null,
                ),

                const SizedBox(height: 8),
                if (auth.error != null &&
                    auth.emailError == null &&
                    auth.passwordError == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(auth.error!,
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w500)),
                  ),

                const SizedBox(height: 32),

                // Nút ĐĂNG NHẬP màu teal
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: auth.loading
                        ? null
                        : () async {
                            if (!_f.currentState!.validate()) return;
                            final ok = await context
                                .read<AuthProvider>()
                                .login(_email.text.trim(), _pass.text);
                            if (!mounted) return;
                            if (ok && mounted) {
                              showAppSnackBar(context, 'Đăng nhập thành công',
                                  icon: Icons.check_circle_rounded);
                            } else {
                              final state = context.read<AuthProvider>();
                              if (state.emailError != null) {
                                _emailFocus.requestFocus();
                              } else {
                                _passFocus.requestFocus();
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: auth.loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text(
                            'ĐĂNG NHẬP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                // Đăng ký ngay
                GestureDetector(
                  onTap: _openRegister,
                  child: RichText(
                    text: const TextSpan(
                      text: 'Chưa có tài khoản? ',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Đăng ký ngay',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Dòng Hoặc
                const Row(
                  children: [
                    Expanded(
                        child: Divider(color: AppColors.border, thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Hoặc',
                        style:
                            TextStyle(color: AppColors.textSub, fontSize: 14),
                      ),
                    ),
                    Expanded(
                        child: Divider(color: AppColors.border, thickness: 1)),
                  ],
                ),

                const SizedBox(height: 24),

                // Nút Google
                OutlinedButton(
                  onPressed: auth.loading
                      ? null
                      : () async {
                          final ok = await context
                              .read<AuthProvider>()
                              .loginWithGoogle();
                          if (ok && mounted) {
                            showAppSnackBar(context, 'Đăng nhập Google thành công', icon: Icons.check_circle_rounded);
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                        height: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Đăng nhập bằng Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
