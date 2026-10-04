import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/auth_provider.dart';
import 'core/condenser_provider.dart';
import 'ui/connect_page.dart';
import 'ui/home_page.dart';
import 'ui/login_page.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const NgungTuApp());
}

class NgungTuApp extends StatefulWidget {
  const NgungTuApp({super.key});

  @override
  State<NgungTuApp> createState() => _NgungTuAppState();
}

class _NgungTuAppState extends State<NgungTuApp> {
  late final AuthProvider _auth = AuthProvider()..bootstrap();
  late final CondenserProvider _condenser = CondenserProvider();

  @override
  void initState() {
    super.initState();
    _condenser.onTelemetry = (state) => _auth.syncTelemetry(state);
  }

  @override
  void dispose() {
    _condenser.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _condenser),
      ],
      child: MaterialApp(
        title: 'Ngưng Tụ STEM',
        debugShowCheckedModeBanner: false,
        theme: NgungTuTheme.dark(),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.booting) {
      return const Scaffold(
        backgroundColor: Color(0xFF071820),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2EC4B6))),
      );
    }

    if (!auth.isLoggedIn) {
      return const LoginPage();
    }

    final condenser = context.watch<CondenserProvider>();

    // Bắt buộc nhập Chip ID + xác thực trước khi xem cảm biến / biểu đồ
    if (!condenser.canEnterSystem) {
      return const ConnectPage();
    }

    return const HomePage();
  }
}
