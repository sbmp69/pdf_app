import 'dart:io';
import 'package:flutter/material.dart';
import 'package:docx_file_viewer/docx_file_viewer.dart';

class DocxViewerPage extends StatelessWidget {
  final String filePath;

  const DocxViewerPage({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    final fileName = filePath.split('/').last.split('\\').last;

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: _buildViewer(),
    );
  }

  Widget _buildViewer() {
    if (filePath.toLowerCase().endsWith('.doc')) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Unsupported Format',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Viewing legacy .doc files is currently not supported. Please use a .docx file.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return DocxView(
      file: File(filePath),
      config: const DocxViewConfig(
        pageWidth: 793,
        enableZoom: true,
      ),
    );
  }
}
