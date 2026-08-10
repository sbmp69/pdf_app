import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  bool _isLoading = false;

  Future<void> _mergePdfs() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.length > 1) {
      setState(() => _isLoading = true);
      try {
        final PdfDocument finalDoc = PdfDocument();
        for (var file in result.files) {
          if (file.path != null) {
            final bytes = await File(file.path!).readAsBytes();
            final doc = PdfDocument(inputBytes: bytes);
            for (int i = 0; i < doc.pages.count; i++) {
              final template = doc.pages[i].createTemplate();
              final page = finalDoc.pages.add();
              page.graphics.drawPdfTemplate(template, const Offset(0, 0));
            }
            doc.dispose();
          }
        }
        
        final List<int> savedBytes = finalDoc.saveSync();
        finalDoc.dispose();

        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/merged_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await File(path).writeAsBytes(savedBytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Merged PDF saved to: $path')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error merging: $e')));
        }
      }
      setState(() => _isLoading = false);
    } else if (result != null && result.files.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 2 PDFs to merge')));
    }
  }

  Future<void> _protectPdf() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      String password = '123'; // In a real app, show a dialog to enter password
      setState(() => _isLoading = true);
      try {
        final bytes = await File(result.files.single.path!).readAsBytes();
        final doc = PdfDocument(inputBytes: bytes);
        
        final security = doc.security;
        security.userPassword = password;
        security.ownerPassword = password;
        security.encryptionOptions = PdfEncryptionOptions.encryptAllContents;
        
        final List<int> savedBytes = doc.saveSync();
        doc.dispose();

        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/protected_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await File(path).writeAsBytes(savedBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Protected PDF saved to: $path')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error protecting PDF: $e')));
        }
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _compressPdf() async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() => _isLoading = true);
      try {
        final bytes = await File(result.files.single.path!).readAsBytes();
        final doc = PdfDocument(inputBytes: bytes);
        
        doc.compressionLevel = PdfCompressionLevel.best;
        
        final List<int> savedBytes = doc.saveSync();
        doc.dispose();

        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await File(path).writeAsBytes(savedBytes);

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Compressed PDF saved to: $path')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unlockPdf() async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      String password = '123'; // In a real app, prompt the user for the password
      setState(() => _isLoading = true);
      try {
        final bytes = await File(result.files.single.path!).readAsBytes();
        final doc = PdfDocument(inputBytes: bytes, password: password);
        
        // Creating a new document and drawing pages removes encryption
        final newDoc = PdfDocument();
        for (int i = 0; i < doc.pages.count; i++) {
          final template = doc.pages[i].createTemplate();
          newDoc.pages.add().graphics.drawPdfTemplate(template, const Offset(0, 0));
        }
        
        final List<int> savedBytes = newDoc.saveSync();
        doc.dispose();
        newDoc.dispose();

        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/unlocked_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await File(path).writeAsBytes(savedBytes);

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unlocked PDF saved to: $path')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: Incorrect password or $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pdfToImage() async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() => _isLoading = true);
      try {
        final bytes = await File(result.files.single.path!).readAsBytes();
        
        final directory = await getApplicationDocumentsDirectory();
        final baseName = 'image_${DateTime.now().millisecondsSinceEpoch}';
        int pageIndex = 1;
        
        // We use the printing package to rasterize PDF pages to images
        // Note: Make sure to import 'package:printing/printing.dart';
        // at the top of the file.
        await for (var page in Printing.raster(bytes, dpi: 300)) {
          final imageBytes = await page.toPng();
          final path = '${directory.path}/${baseName}_page_$pageIndex.png';
          await File(path).writeAsBytes(imageBytes);
          pageIndex++;
        }

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved ${pageIndex - 1} images to: ${directory.path}')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pdfToText() async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() => _isLoading = true);
      try {
        final bytes = await File(result.files.single.path!).readAsBytes();
        final doc = PdfDocument(inputBytes: bytes);
        
        String extractedText = PdfTextExtractor(doc).extractText();
        doc.dispose();
        
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/extracted_text_${DateTime.now().millisecondsSinceEpoch}.txt';
        await File(path).writeAsString(extractedText);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Text extracted to: $path')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Toolkit'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildToolItem(context, Icons.merge_type, 'Merge PDFs', 'Combine multiple PDF files into one.', _mergePdfs),
              _buildToolItem(context, Icons.lock, 'Protect PDF', 'Add a password to your PDF document.', _protectPdf),
              _buildToolItem(context, Icons.compress, 'Compress PDF', 'Reduce the file size of your PDFs.', _compressPdf),
              _buildToolItem(context, Icons.lock_open, 'Unlock PDF', 'Remove password protection from a PDF.', _unlockPdf),
              _buildToolItem(context, Icons.image, 'PDF to Image', 'Convert PDF pages into high-quality images.', _pdfToImage),
              _buildToolItem(context, Icons.text_snippet, 'PDF to Text', 'Extract text from a PDF file.', _pdfToText),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildToolItem(BuildContext context, IconData icon, String title, String subtitle, VoidCallback? onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title coming soon!')),
          );
        },
      ),
    );
  }
}
