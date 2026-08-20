import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

class SplitPdfPage extends StatefulWidget {
  final String pdfPath;
  const SplitPdfPage({super.key, required this.pdfPath});

  @override
  State<SplitPdfPage> createState() => _SplitPdfPageState();
}

class _SplitPdfPageState extends State<SplitPdfPage> {
  bool _isLoading = true;
  int _totalPages = 0;
  final TextEditingController _splitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final bytes = await File(widget.pdfPath).readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      setState(() {
        _totalPages = doc.pages.count;
        _isLoading = false;
      });
      doc.dispose();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading PDF: $e')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _splitPdf() async {
    final splitAfter = int.tryParse(_splitController.text);
    if (splitAfter == null || splitAfter < 1 || splitAfter >= _totalPages) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid split page number')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bytes = await File(widget.pdfPath).readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);

      final doc1 = PdfDocument();
      final doc2 = PdfDocument();

      for (int i = 0; i < doc.pages.count; i++) {
        final template = doc.pages[i].createTemplate();
        if (i < splitAfter) {
          final page = doc1.pages.add();
          page.graphics.drawPdfTemplate(template, const Offset(0, 0));
        } else {
          final page = doc2.pages.add();
          page.graphics.drawPdfTemplate(template, const Offset(0, 0));
        }
      }

      final bytes1 = doc1.saveSync();
      final bytes2 = doc2.saveSync();

      doc1.dispose();
      doc2.dispose();
      doc.dispose();

      final directory = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      
      await File('${directory.path}/Split_Part1_$ts.pdf').writeAsBytes(bytes1);
      await File('${directory.path}/Split_Part2_$ts.pdf').writeAsBytes(bytes2);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully split into 2 files!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error splitting: $e')));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Split PDF')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.call_split, size: 64, color: Colors.blue),
                const SizedBox(height: 24),
                Text('This document has $_totalPages pages.'),
                const SizedBox(height: 16),
                TextField(
                  controller: _splitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Split after page number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _splitPdf,
                    child: const Text('Split PDF'),
                  ),
                )
              ],
            ),
          ),
    );
  }
}
