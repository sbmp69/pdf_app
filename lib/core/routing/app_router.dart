import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/scanner/presentation/pages/scanner_page.dart';
import '../../features/scanner/presentation/pages/qr_scanner_page.dart';
import '../../features/tools/presentation/pages/pdf_editor_page.dart';
import '../../features/tools/presentation/pages/pdf_viewer_page.dart';
import '../../features/tools/presentation/pages/docx_viewer_page.dart';

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
      GoRoute(
        path: '/pdf_viewer',
        builder: (context, state) {
          final pdfPath = state.extra as String;
          return PdfViewerPage(pdfPath: pdfPath);
        },
      ),
      GoRoute(
        path: '/docx_viewer',
        builder: (context, state) {
          final filePath = state.extra as String;
          return DocxViewerPage(filePath: filePath);
        },
      ),
      GoRoute(
        path: '/pdf_editor',
        name: 'pdf_editor',
        builder: (context, state) {
          final pdfPath = state.extra as String?;
          return PdfEditorPage(pdfPath: pdfPath);
        },
      ),
    ],
  );
}
