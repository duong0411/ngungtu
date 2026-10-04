import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth_provider.dart';
import 'theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final pass = _pass.text;
    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đủ tên, email và mật khẩu'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: NgungTuTheme.panel,
        ),
      );
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email chưa đúng định dạng — kiểm tra lại (ví dụ: ten@gmail.com)'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: NgungTuTheme.panel,
        ),
      );
      return;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu cần ít nhất 6 ký tự'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: NgungTuTheme.panel,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(name, email, '', pass);
    if (!mounted) return;
    if (ok) {
      // AuthGate tự chuyển sang trang chủ khi đã đăng nhập
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Đăng ký chưa thành công'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: NgungTuTheme.panel,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF062029), NgungTuTheme.deep],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: NgungTuTheme.soft),
                    ),
                    Text('Tạo tài khoản', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                  children: [
                    Text(
                      'Chào mừng đến Ngưng Tụ',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chỉ cần tên, email và mật khẩu để bắt đầu theo dõi máy thu nước.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: NgungTuTheme.soft.withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 28),
                    _field(_name, 'Họ và tên', Icons.person_outline_rounded),
                    const SizedBox(height: 14),
                    _field(_email, 'Email', Icons.mail_outline_rounded, keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    _field(
                      _pass,
                      'Mật khẩu',
                      Icons.lock_outline_rounded,
                      obscure: _obscure,
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: NgungTuTheme.soft.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: auth.busy ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: NgungTuTheme.aqua,
                          foregroundColor: NgungTuTheme.deep,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: auth.busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: NgungTuTheme.deep),
                              )
                            : const Text('Hoàn tất', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: NgungTuTheme.soft, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: NgungTuTheme.soft.withValues(alpha: 0.55)),
        prefixIcon: Icon(icon, color: NgungTuTheme.aqua),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: NgungTuTheme.aqua, width: 1.4),
        ),
      ),
    );
  }
}
