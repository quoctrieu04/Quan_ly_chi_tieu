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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _f,
          child: Column(children: [
            TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Họ tên'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Nhập họ tên' : null),
            TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Nhập email' : null),
            TextFormField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                validator: (v) =>
                    (v == null || v.length < 6) ? '≥ 6 ký tự' : null),
            const SizedBox(height: 12),
            if (auth.error != null)
              Text(auth.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: auth.loading
                  ? null
                  : () async {
                      if (!_f.currentState!.validate()) return;
                      final ok = await context
                          .read<AuthProvider>()
                          .register(_name.text, _email.text, _pass.text);
                      if (ok && mounted) {
                        safeShowSnackBar(
                            context,
                            const SnackBar(
                                content: Text('Đăng ký thành công')));
                        Navigator.pop(context); // quay về SettingsPage
                      }
                    },
              child: auth.loading
                  ? const CircularProgressIndicator()
                  : const Text('Tạo tài khoản'),
            ),
          ]),
        ),
      ),
    );
  }
}
