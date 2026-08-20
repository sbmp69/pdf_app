import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class DeletePagesPage extends StatefulWidget {
  final String pdfPath;
  const DeletePagesPage({super.key, required this.pdfPath});

  @override
  State<DeletePagesPage> createState() => _DeletePagesPageState();
}

class _DeletePagesPageState extends State<DeletePagesPage> {
  bool _isLoading = true;
  List<PdfRaster> _pages = [];
  final Set<int> _selectedPagesToDelete = {};

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

  Future<void> _deleteSelectedPages() async {
    if (_selectedPagesToDelete.isEmpty) return;
    if (_selectedPagesToDelete.length == _pages.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete all pages')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bytes = await File(widget.pdfPath).readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);

      final newDoc = PdfDocument();

      for (int i = 0; i < doc.pages.count; i++) {
        if (!_selectedPagesToDelete.contains(i)) {
          final template = doc.pages[i].createTemplate();
          final page = newDoc.pages.add();
          page.graphics.drawPdfTemplate(template, const Offset(0, 0));
        }
      }

      final savedBytes = newDoc.saveSync();
      newDoc.dispose();
      doc.dispose();

      final directory = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      await File('${directory.path}/Deleted_Pages_$ts.pdf').writeAsBytes(savedBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pages deleted and saved!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Pages'),
        actions: [
          if (_selectedPagesToDelete.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedPages,
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedPagesToDelete.contains(index);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedPagesToDelete.remove(index);
                      } else {
                        _selectedPagesToDelete.add(index);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.red : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: FutureBuilder(
                            future: _pages[index].toImage(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return RawImage(image: snapshot.data, fit: BoxFit.contain);
                              }
                              return const Center(child: CircularProgressIndicator());
                            }
                          ),
                        ),
                        if (isSelected)
                          const Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(Icons.check_circle, color: Colors.red),
                          ),
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              color: Colors.black54,
                              child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
