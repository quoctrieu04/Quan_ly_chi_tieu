import 'package:chitieu/utils/safe_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../auth/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  bool _savingName = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl.text = auth.user?['name'] ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _requireLoginThen(
      BuildContext context, Future<void> Function() task) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      await Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
      if (!mounted) return;
      if (!context.read<AuthProvider>().isAuthenticated) return;
    }
    await task();
  }

  Future<void> _saveName() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) {
      safeShowSnackBar(
          context, const SnackBar(content: Text('Tên không được để trống')));
      _nameFocus.requestFocus();
      return;
    }
    setState(() => _savingName = true);
    try {
      await _requireLoginThen(context, () async {
        final ok = await context.read<AuthProvider>().updateName(newName);
        if (ok) {
          if (!mounted) return;
          safeShowSnackBar(context,
              const SnackBar(content: Text('Cập nhật tên thành công')));
        } else {
          if (!mounted) return;
          safeShowSnackBar(
              context, const SnackBar(content: Text('Không thể cập nhật tên')));
        }
      });
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _openChangePasswordSheet() async {
    await _requireLoginThen(context, () async {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (ctx) => const _ChangePasswordSheet(),
      );
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (confirm != true) return;

    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pop(context); // quay lại trang trước (Settings)
    safeShowSnackBar(context, const SnackBar(content: Text('Đã đăng xuất')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      // Chưa đăng nhập → mời đăng nhập
      return Scaffold(
        appBar: AppBar(title: const Text('Thông tin tài khoản')),
        body: Center(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
            icon: const Icon(Icons.login),
            label: const Text('Đăng nhập để xem hồ sơ'),
          ),
        ),
      );
    }

    final user = auth.user ?? {};
    final email = user['email'] ?? '';
    final createdAt = user['created_at']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin tài khoản')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header avatar + tên
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.person, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hồ sơ của bạn',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: _openChangePasswordSheet,
                tooltip: 'Đổi mật khẩu',
                icon: const Icon(Icons.lock_reset_rounded),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Thẻ: tên (chỉnh sửa)
          Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Tên hiển thị',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    focusNode: _nameFocus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveName(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Nhập tên của bạn',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _savingName ? null : _saveName,
                    icon: _savingName
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_rounded),
                    label: const Text('Lưu'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Thẻ: thông tin đọc-only
          Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  SelectableText(email),
                  const SizedBox(height: 14),
                  Text('Ngày tạo',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Text(createdAt),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Nút đổi mật khẩu phụ (ngoài appbar)
          OutlinedButton.icon(
            onPressed: _openChangePasswordSheet,
            icon: const Icon(Icons.password_rounded),
            label: const Text('Đổi mật khẩu'),
          ),

          const SizedBox(height: 12),

          // Nút Đăng xuất
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _ob1 = true, _ob2 = true, _ob3 = true;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _pwdRule(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Không được để trống';
    if (s.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_new.text.trim() != _confirm.text.trim()) {
      safeShowSnackBar(context,
          const SnackBar(content: Text('Xác nhận mật khẩu không khớp')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final ok = await context.read<AuthProvider>().changePassword(
            oldPassword: _old.text.trim(),
            newPassword: _new.text.trim(),
          );
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context);
        safeShowSnackBar(
            context, const SnackBar(content: Text('Đổi mật khẩu thành công')));
      } else {
        safeShowSnackBar(
            context, const SnackBar(content: Text('Đổi mật khẩu thất bại')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Đổi mật khẩu',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _old,
              obscureText: _ob1,
              validator: _pwdRule,
              decoration: InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(_ob1 ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _ob1 = !_ob1),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _new,
              obscureText: _ob2,
              validator: _pwdRule,
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(_ob2 ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _ob2 = !_ob2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirm,
              obscureText: _ob3,
              validator: _pwdRule,
              decoration: InputDecoration(
                labelText: 'Nhập lại mật khẩu mới',
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(_ob3 ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _ob3 = !_ob3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: const Text('Xác nhận đổi mật khẩu'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
