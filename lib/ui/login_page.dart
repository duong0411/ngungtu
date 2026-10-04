import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../core/auth_provider.dart';
import '../core/config.dart';
import 'register_page.dart';
import 'theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_email.text, _pass.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Đăng nhập thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF041018), NgungTuTheme.deep, Color(0xFF0B3040)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
            children: [
              Text(
                'NGƯNG TỤ',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 48,
                      height: 0.95,
                    ),
              ).animate().fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 8),
              Text(
                'STEM · đăng nhập database AloT',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: NgungTuTheme.ice.withValues(alpha: 0.9),
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chip ID cố định: ${AppConfig.chipId}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: NgungTuTheme.soft.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: 36),
              _field(_email, 'Email', Icons.mail_outline_rounded),
              const SizedBox(height: 12),
              _field(
                _pass,
                'Mật khẩu',
                Icons.lock_outline_rounded,
                obscure: _obscure,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: NgungTuTheme.soft.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: auth.busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NgungTuTheme.aqua,
                    foregroundColor: NgungTuTheme.deep,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: auth.busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: NgungTuTheme.deep),
                        )
                      : const Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: Text(
                  'Chưa có tài khoản? Đăng ký',
                  style: TextStyle(color: NgungTuTheme.ice.withValues(alpha: 0.9)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Dùng chung API MongoDB: ${AppConfig.apiBaseUrl}\nSau đăng nhập app tự gắn thiết bị chip ${AppConfig.chipId}.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: NgungTuTheme.soft.withValues(alpha: 0.55),
                      fontSize: 12,
                      height: 1.4,
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
    String hint,
    IconData icon, {
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(color: NgungTuTheme.soft),
      keyboardType: hint == 'Email' ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: NgungTuTheme.soft.withValues(alpha: 0.4)),
        prefixIcon: Icon(icon, color: NgungTuTheme.aqua),
        suffixIcon: suffix,
        filled: true,
        fillColor: NgungTuTheme.panel.withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
