import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

class RemoveWatermarkPage extends StatefulWidget {
  final String pdfPath;
  const RemoveWatermarkPage({super.key, required this.pdfPath});

  @override
  State<RemoveWatermarkPage> createState() => _RemoveWatermarkPageState();
}

class _RemoveWatermarkPageState extends State<RemoveWatermarkPage> {
  bool _isLoading = false;
  final TextEditingController _textController = TextEditingController();

  Future<void> _removeWatermark() async {
    final targetText = _textController.text.trim();
    if (targetText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the watermark text to remove')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bytes = await File(widget.pdfPath).readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);

      // Attempt 1: Remove Watermark Annotations
      for (int i = 0; i < doc.pages.count; i++) {
        final page = doc.pages[i];
        for (int j = page.annotations.count - 1; j >= 0; j--) {
          final annotation = page.annotations[j];
          if (annotation.text.toLowerCase().contains(targetText.toLowerCase())) {
            page.annotations.remove(annotation);
          }
        }
      }

      // Attempt 2: Draw white rectangles over the specific text using TextExtractor
      final extractor = PdfTextExtractor(doc);
      for (int i = 0; i < doc.pages.count; i++) {
        final lines = extractor.extractTextLines(startPageIndex: i, endPageIndex: i);
        for (var line in lines) {
          if (line.text.toLowerCase().contains(targetText.toLowerCase())) {
            // Draw a white rectangle over the text bounds
            doc.pages[i].graphics.drawRectangle(
              brush: PdfSolidBrush(PdfColor(255, 255, 255)),
              bounds: line.bounds,
            );
          }
        }
      }

      final savedBytes = doc.saveSync();
      doc.dispose();

      final directory = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      await File('${directory.path}/Cleaned_$ts.pdf').writeAsBytes(savedBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Watermark successfully scrubbed and saved!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Remove Watermark')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.format_color_reset, size: 64, color: Colors.blue),
                  const SizedBox(height: 24),
                  const Text(
                    'Enter the exact text of the watermark you want to remove. We will attempt to scrub it from every page.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: 'Watermark Text',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _removeWatermark,
                      child: const Text('Remove Watermark'),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
