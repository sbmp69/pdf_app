import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/pdf_generator.dart';
import '../../../../core/utils/ocr_scanner.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  List<String> _pictures = [];
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      
      if (images.isEmpty) {
        // Fallback to taking a single picture if user wants to use camera
        final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
        if (photo != null) {
          images.add(photo);
        }
      }

      if (!mounted) return;
      setState(() {
        _pictures.addAll(images.map((e) => e.path));
        _isScanning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get pictures: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto start scanner when opening this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanned Documents'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isScanning
          ? const Center(child: CircularProgressIndicator())
          : _pictures.isEmpty
              ? const Center(child: Text('No documents scanned'))
              : ListView.builder(
                  itemCount: _pictures.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Image.file(File(_pictures[index])),
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_pictures.isNotEmpty)
            FloatingActionButton.extended(
              heroTag: 'extract_text',
              onPressed: () async {
                setState(() => _isScanning = true);
                try {
                  String text = '';
                  for (var pic in _pictures) {
                    text += await OcrScanner.extractTextFromImage(pic) + '\n\n';
                  }
                  if (!mounted) return;
                  setState(() => _isScanning = false);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Extracted Text'),
                      content: SingleChildScrollView(child: Text(text)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        )
                      ],
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  setState(() => _isScanning = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('OCR failed: $e')),
                  );
                }
              },
              icon: const Icon(Icons.text_fields),
              label: const Text('Extract Text'),
            ),
          const SizedBox(height: 16),
          if (_pictures.isNotEmpty)
            FloatingActionButton.extended(
              heroTag: 'save_pdf',
              onPressed: () async {
                setState(() => _isScanning = true);
                try {
                  // We need to import the generator first, so let's assume it's imported above
                  // Actually, I'll add the import in the next call.
                  final file = await PdfGenerator.generatePdfFromImages(_pictures, 'Scan_${DateTime.now().millisecondsSinceEpoch}');
                  if (!mounted) return;
                  setState(() => _isScanning = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved to: ${file.path}')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  setState(() => _isScanning = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save PDF: $e')),
                  );
                }
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Save PDF'),
            ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'add_page',
            onPressed: _startScan,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Add Page'),
          ),
        ],
      ),
    );
  }
}
