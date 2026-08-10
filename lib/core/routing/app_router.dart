import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/scanner/presentation/pages/scanner_page.dart';
import '../../features/scanner/presentation/pages/qr_scanner_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/scanner',
        name: 'scanner',
        builder: (context, state) => const ScannerPage(),
      ),
      GoRoute(
        path: '/qr_scanner',
        name: 'qr_scanner',
        builder: (context, state) => const QRScannerPage(),
      ),
    ],
  );
}
