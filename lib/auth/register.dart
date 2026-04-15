import 'package:chitieu/utils/safe_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _f = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  static const _mint = Color(0xFF2EC4B6);
  static const _tealEdge = Color(0xFF14B8A6);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFBFE),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _f,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_add_alt_1_rounded, size: 80, color: _mint),
                const SizedBox(height: 24),
                Text(
                  'Tạo tài khoản mới',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tham gia ngay để kiểm soát tài chính',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 48),
                _buildTextField(
                  controller: _name,
                  icon: Icons.badge_rounded,
                  label: 'Họ tên',
                  isDark: isDark,
                  validator: (v) => (v == null || v.isEmpty) ? 'Nhập họ tên' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _email,
                  icon: Icons.email_rounded,
                  label: 'Email',
                  isDark: isDark,
                  validator: (v) => (v == null || v.isEmpty) ? 'Nhập email hợp lệ' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _pass,
                  icon: Icons.lock_rounded,
                  label: 'Mật khẩu',
                  obscure: true,
                  isDark: isDark,
                  validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu phải từ 6 ký tự' : null,
                ),
                const SizedBox(height: 24),
                if (auth.error != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 22),
                        const SizedBox(width: 10),
                        Expanded(child: Text(auth.error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13))),
                      ],
                    ),
                  ),
                if (auth.error != null) const SizedBox(height: 24),
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(colors: [_tealEdge, _mint]),
                    boxShadow: [
                      BoxShadow(color: _mint.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: auth.loading
                        ? null
                        : () async {
                            if (!_f.currentState!.validate()) return;
                            final ok = await context.read<AuthProvider>().register(_name.text, _email.text, _pass.text);
                            if (ok && mounted) {
                              safeShowSnackBar(context, const SnackBar(content: Text('Đăng ký thành công!', style: TextStyle(fontWeight: FontWeight.bold))));
                              Navigator.pop(context);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: auth.loading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Text('TẠO TÀI KHOẢN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Đã có tài khoản? ', style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text('Đăng nhập', style: TextStyle(color: _mint, fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required bool isDark,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: _mint),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _mint, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }
}
