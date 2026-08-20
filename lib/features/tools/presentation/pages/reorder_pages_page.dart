import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class ReorderPagesPage extends StatefulWidget {
  final String pdfPath;
  const ReorderPagesPage({super.key, required this.pdfPath});

  @override
  State<ReorderPagesPage> createState() => _ReorderPagesPageState();
}

class _ReorderPagesPageState extends State<ReorderPagesPage> {
  bool _isLoading = true;
  List<PdfRaster> _pages = [];
  List<int> _pageOrder = []; // Stores the new sequence of original page indices

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final bytes = await File(widget.pdfPath).readAsBytes();
      
      final rasterPages = <PdfRaster>[];
      await for (var page in Printing.raster(bytes, dpi: 72)) {
        rasterPages.add(page);
      }
      
      if (mounted) {
        setState(() {
          _pages = rasterPages;
          _pageOrder = List.generate(rasterPages.length, (index) => index);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading PDF: $e')));
        Navigator.pop(context);
      }
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final int item = _pageOrder.removeAt(oldIndex);
      _pageOrder.insert(newIndex, item);
    });
  }

  Future<void> _saveReorderedPdf() async {
    setState(() => _isLoading = true);
    try {
      final bytes = await File(widget.pdfPath).readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);

      final newDoc = PdfDocument();

      for (int originalIndex in _pageOrder) {
        final template = doc.pages[originalIndex].createTemplate();
        final page = newDoc.pages.add();
        page.graphics.drawPdfTemplate(template, const Offset(0, 0));
      }

      final savedBytes = newDoc.saveSync();
      newDoc.dispose();
      doc.dispose();

      final directory = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      await File('${directory.path}/Reordered_$ts.pdf').writeAsBytes(savedBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pages reordered and saved!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reorder Pages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveReorderedPdf,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _pageOrder.length,
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final originalIndex = _pageOrder[index];
                return ListTile(
                  key: ValueKey(originalIndex),
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: FutureBuilder(
                      future: _pages[originalIndex].toImage(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return RawImage(image: snapshot.data, fit: BoxFit.contain);
                        }
                        return const Center(child: CircularProgressIndicator());
                      }
                    ),
                  ),
                  title: Text('Page ${originalIndex + 1}'),
                  trailing: const Icon(Icons.drag_handle),
                );
              },
            ),
    );
  }
}
