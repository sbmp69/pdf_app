import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerPage extends StatelessWidget {
  final String pdfPath;

  const PdfViewerPage({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    final fileName = pdfPath.split('/').last.split('\\').last;

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_document),
            tooltip: 'Edit PDF',
            onPressed: () {
              context.push('/pdf_editor', extra: pdfPath);
            },
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy), // AI icon
            tooltip: 'Ask AI',
            onPressed: () {
              context.push('/pdf_chat', extra: pdfPath);
            },
          ),
        ],
      ),
      body: SfPdfViewer.file(File(pdfPath)),
    );
  }
}
