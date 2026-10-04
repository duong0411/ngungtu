import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/condenser_provider.dart';
import 'ui/home_page.dart';
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
  late final CondenserProvider _provider = CondenserProvider()..start();

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: MaterialApp(
        title: 'Ngưng Tụ STEM',
        debugShowCheckedModeBanner: false,
        theme: NgungTuTheme.dark(),
        home: const HomePage(),
      ),
    );
  }
}
