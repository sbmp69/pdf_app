import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

class ApplyWatermarkPage extends StatefulWidget {
  final String pdfPath;
  const ApplyWatermarkPage({super.key, required this.pdfPath});

  @override
  State<ApplyWatermarkPage> createState() => _ApplyWatermarkPageState();
}

class _ApplyWatermarkPageState extends State<ApplyWatermarkPage> {
  bool _isLoading = false;
  final TextEditingController _textController = TextEditingController();

  Future<void> _applyWatermark() async {
    final watermarkText = _textController.text.trim();
    if (watermarkText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter watermark text')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bytes = await File(widget.pdfPath).readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      
      final font = PdfStandardFont(PdfFontFamily.helvetica, 60);
      final brush = PdfSolidBrush(PdfColor(255, 0, 0, 100)); // Semi-transparent red

      for (int i = 0; i < doc.pages.count; i++) {
        final page = doc.pages[i];
        final graphics = page.graphics;
        
        graphics.save();
        graphics.setTransparency(0.5);
        graphics.translateTransform(page.size.width / 2, page.size.height / 2);
        graphics.rotateTransform(-45);
        
        final size = font.measureString(watermarkText);
        graphics.drawString(
          watermarkText, 
          font, 
          brush: brush,
          bounds: Rect.fromLTWH(-size.width / 2, -size.height / 2, size.width, size.height),
        );
        graphics.restore();
      }

      final savedBytes = doc.saveSync();
      doc.dispose();

      final directory = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      await File('${directory.path}/Watermarked_$ts.pdf').writeAsBytes(savedBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Watermark applied successfully!')));
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
      appBar: AppBar(title: const Text('Apply Watermark')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.branding_watermark, size: 64, color: Colors.blue),
                  const SizedBox(height: 24),
                  const Text('Enter the text you want stamped diagonally across every page.'),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: 'Watermark Text (e.g. CONFIDENTIAL)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _applyWatermark,
                      child: const Text('Apply Watermark'),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
