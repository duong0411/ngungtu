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
  final _phone = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(_name.text, _email.text, _phone.text, _pass.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(); // về AuthGate → Home
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Đăng ký thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: NgungTuTheme.deep,
      appBar: AppBar(
        backgroundColor: NgungTuTheme.panel,
        title: const Text('Đăng ký tài khoản'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _box(_name, 'Họ tên', Icons.person_outline),
          const SizedBox(height: 12),
          _box(_email, 'Email', Icons.mail_outline),
          const SizedBox(height: 12),
          _box(_phone, 'Số điện thoại', Icons.phone_outlined),
          const SizedBox(height: 12),
          _box(_pass, 'Mật khẩu', Icons.lock_outline, obscure: true),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: auth.busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: NgungTuTheme.aqua,
                foregroundColor: NgungTuTheme.deep,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: auth.busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: NgungTuTheme.deep),
                    )
                  : const Text('Tạo tài khoản', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(TextEditingController c, String hint, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(color: NgungTuTheme.soft),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: NgungTuTheme.soft.withValues(alpha: 0.4)),
        prefixIcon: Icon(icon, color: NgungTuTheme.aqua),
        filled: true,
        fillColor: NgungTuTheme.panel.withValues(alpha: 0.85),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}
