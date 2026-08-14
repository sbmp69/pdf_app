import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/database/database_helper.dart';
import 'core/widgets/app_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const ProviderScope(child: ScanProApp()));
}

class ScanProApp extends StatefulWidget {
  const ScanProApp({super.key});

  @override
  State<ScanProApp> createState() => _ScanProAppState();
}

class _ScanProAppState extends State<ScanProApp> with WidgetsBindingObserver {
  static const platform = MethodChannel('app.channel.shared.data');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getSharedData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _getSharedData();
    }
  }

  Future<void> _getSharedData() async {
    try {
      final String? sharedData = await platform.invokeMethod('getSharedData');
      if (sharedData != null && sharedData.isNotEmpty) {
        if (sharedData.toLowerCase().endsWith('.pdf')) {
          AppRouter.router.push('/pdf_viewer', extra: sharedData);
        } else if (sharedData.toLowerCase().endsWith('.docx') || sharedData.toLowerCase().endsWith('.doc')) {
          AppRouter.router.push('/docx_viewer', extra: sharedData);
        }
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to get shared data: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLockScreen(
      child: MaterialApp.router(
        title: 'PDF Master: Scan, Edit & Merge',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
