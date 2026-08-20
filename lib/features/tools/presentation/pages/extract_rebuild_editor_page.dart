import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdf/pdf.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class ExtractRebuildEditorPage extends StatefulWidget {
  final String pdfPath;
  const ExtractRebuildEditorPage({super.key, required this.pdfPath});

  @override
  State<ExtractRebuildEditorPage> createState() => _ExtractRebuildEditorPageState();
}

class _ExtractRebuildEditorPageState extends State<ExtractRebuildEditorPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _extractText();
  }

  Future<void> _extractText() async {
    try {
      final bytes = await File(widget.pdfPath).readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(doc);
      
      String allText = '';
      for (int i = 0; i < doc.pages.count; i++) {
        final lines = extractor.extractTextLines(startPageIndex: i, endPageIndex: i);
        for (var line in lines) {
          allText += '${line.text}\n';
        }
        allText += '\n'; // Page break spacing
      }
      doc.dispose();

      if (mounted) {
        setState(() {
          _textController.text = allText.trim();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error extracting text: $e')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveAsNewPdf() async {
    setState(() => _isSaving = true);
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: p.PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Text(
                _textController.text,
                style: const pw.TextStyle(fontSize: 12),
              ),
            ];
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/Rebuilt_Doc_$ts.pdf';
      await File(path).writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved as a brand new PDF!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving PDF: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Editor'),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text('Save as PDF', style: TextStyle(color: Colors.white)),
              onPressed: _isSaving ? null : _saveAsNewPdf,
            ),
        ],
      ),
      body: _isLoading || _isSaving
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_isSaving ? 'Rebuilding PDF...' : 'Extracting text...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    hintText: 'No text could be extracted...',
                  ),
                  style: const TextStyle(height: 1.5),
                ),
              ),
            ),
    );
  }
}
