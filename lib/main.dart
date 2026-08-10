import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/database/database_helper.dart';
import 'core/widgets/app_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const ProviderScope(child: ScanProApp()));
}

class ScanProApp extends StatelessWidget {
  const ScanProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLockScreen(
      child: MaterialApp.router(
        title: 'ScanPro AI',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
