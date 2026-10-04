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

class NgungTuApp extends StatelessWidget {
  const NgungTuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CondenserProvider()..start(),
      child: MaterialApp(
        title: 'Ngưng Tụ STEM',
        debugShowCheckedModeBanner: false,
        theme: NgungTuTheme.dark(),
        home: const HomePage(),
      ),
    );
  }
}
