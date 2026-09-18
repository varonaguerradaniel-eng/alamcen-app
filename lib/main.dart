import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'l10n/app_language.dart';
import 'screens/splash_screen.dart';
import 'services/database_helper.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize database
  await DatabaseHelper.instance.database;

  final language = AppLanguage();
  await language.load();

  runApp(
    ChangeNotifierProvider.value(
      value: language,
      child: const WarehouseEliteApp(),
    ),
  );
}

class WarehouseEliteApp extends StatelessWidget {
  const WarehouseEliteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLanguage>();
    return MaterialApp(
      title: language.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
