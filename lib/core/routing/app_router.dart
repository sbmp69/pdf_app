import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/scanner/presentation/pages/scanner_page.dart';
import '../../features/scanner/presentation/pages/qr_scanner_page.dart';
import '../../features/tools/presentation/pages/pdf_editor_page.dart';
import '../../features/tools/presentation/pages/pdf_viewer_page.dart';
import '../../features/tools/presentation/pages/docx_viewer_page.dart';
import '../../features/tools/presentation/pages/pdf_chat_page.dart';
import '../../features/tools/presentation/pages/split_pdf_page.dart';
import '../../features/tools/presentation/pages/delete_pages_page.dart';
import '../../features/tools/presentation/pages/reorder_pages_page.dart';
import '../../features/tools/presentation/pages/remove_watermark_page.dart';
import '../../features/tools/presentation/pages/extract_rebuild_editor_page.dart';
import '../../features/tools/presentation/pages/apply_watermark_page.dart';
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
      GoRoute(
        path: '/pdf_chat',
        name: 'pdf_chat',
        builder: (context, state) {
          final pdfPath = state.extra as String;
          return PdfChatPage(pdfPath: pdfPath);
        },
      ),
      GoRoute(
        path: '/split_pdf',
        name: 'split_pdf',
        builder: (context, state) {
          final pdfPath = state.extra as String;
          return SplitPdfPage(pdfPath: pdfPath);
        },
      ),
      GoRoute(
        path: '/delete_pages',
        name: 'delete_pages',
        builder: (context, state) {
          final pdfPath = state.extra as String;
          return DeletePagesPage(pdfPath: pdfPath);
        },
      ),
      GoRoute(
        path: '/reorder_pages',
        name: 'reorder_pages',
        builder: (context, state) {
          final pdfPath = state.extra as String;
          return ReorderPagesPage(pdfPath: pdfPath);
        },
      ),
      GoRoute(
        path: '/remove_watermark',
        name: 'remove_watermark',
        builder: (context, state) {
          final pdfPath = state.extra as String;
          return RemoveWatermarkPage(pdfPath: pdfPath);
        },
      ),
      GoRoute(
        path: '/extract_rebuild_editor',
        name: 'extract_rebuild_editor',
        builder: (context, state) {
          final pdfPath = state.extra as String;
          return ExtractRebuildEditorPage(pdfPath: pdfPath);
        },
      ),
      GoRoute(
        path: '/apply_watermark',
        name: 'apply_watermark',
        builder: (context, state) {
          final pdfPath = state.extra as String;
          return ApplyWatermarkPage(pdfPath: pdfPath);
        },
      ),
    ],
  );
}
