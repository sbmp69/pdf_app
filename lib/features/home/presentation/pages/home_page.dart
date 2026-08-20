import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import '../widgets/quick_tools_grid.dart';
import '../../../documents/presentation/pages/documents_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  Future<void> _handleToolAction(String action) async {
    switch (action) {
      case 'Merge PDF':
        await _mergePdfs();
        break;
      case 'Compress PDF':
        await _compressPdf();
        break;
      case 'Protect PDF':
        await _protectPdf();
        break;
      case 'Edit PDF':
        context.push('/pdf_editor');
        break;
      case 'AI Chat':
        await _aiChat();
        break;
    }
  }

  Future<void> _aiChat() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      if (mounted) {
        context.push('/pdf_chat', extra: result.files.single.path!);
      }
    }
  }

  Future<void> _mergePdfs() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.length > 1) {
      TextEditingController nameController = TextEditingController(text: 'Merged_${DateTime.now().millisecondsSinceEpoch}');
      final String? customName = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Save Merged PDF'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Document Name', suffixText: '.pdf'),
              autofocus: true,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  Navigator.pop(context, nameController.text.trim());
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      );

      if (customName == null) return;

      setState(() => _isLoading = true);
      try {
        final PdfDocument finalDoc = PdfDocument();
        finalDoc.pageSettings.margins.all = 0; // Remove default margins
        
        for (var file in result.files) {
          if (file.path != null) {
            final bytes = await File(file.path!).readAsBytes();
            final doc = PdfDocument(inputBytes: bytes);
            for (int i = 0; i < doc.pages.count; i++) {
              final template = doc.pages[i].createTemplate();
              // Match the original page size exactly
              finalDoc.pageSettings.size = doc.pages[i].size;
              final page = finalDoc.pages.add();
              page.graphics.drawPdfTemplate(template, const Offset(0, 0));
            }
            doc.dispose();
          }
        }
        
        final List<int> savedBytes = finalDoc.saveSync();
        finalDoc.dispose();

        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/$customName.pdf';
        await File(path).writeAsBytes(savedBytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Merged PDF saved! Check Documents tab.')));
          setState(() => _isLoading = false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error merging PDFs: $e')));
          setState(() => _isLoading = false);
        }
      }
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
      TextEditingController nameController = TextEditingController(text: 'Protected_${DateTime.now().millisecondsSinceEpoch}');
      TextEditingController passController = TextEditingController();

      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Protect PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'New File Name', suffixText: '.pdf'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (passController.text.isEmpty || nameController.text.isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Protect'),
            ),
          ],
        ),
      );

      if (proceed != true) return;

      setState(() => _isLoading = true);
      try {
        final bytes = await File(result.files.single.path!).readAsBytes();
        final doc = PdfDocument(inputBytes: bytes);
        
        final security = doc.security;
        security.userPassword = passController.text;
        security.ownerPassword = passController.text;
        security.encryptionOptions = PdfEncryptionOptions.encryptAllContents;
        
        final List<int> savedBytes = doc.saveSync();
        doc.dispose();

        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/${nameController.text}.pdf';
        await File(path).writeAsBytes(savedBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Protected PDF saved successfully')));
          setState(() => _selectedIndex = 1); // Go to documents tab
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
      TextEditingController nameController = TextEditingController(text: 'Compressed_${DateTime.now().millisecondsSinceEpoch}');
      final String? customName = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Save Compressed PDF'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Document Name', suffixText: '.pdf'),
              autofocus: true,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  Navigator.pop(context, nameController.text.trim());
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      );

      if (customName == null) return;

      setState(() => _isLoading = true);
      try {
        final pdfBytes = await File(result.files.single.path!).readAsBytes();
        
        final compressedPdf = pw.Document();
        
        // Rasterize PDF pages to images at 72 DPI to save space
        await for (var page in Printing.raster(pdfBytes, dpi: 72)) {
          final pngBytes = await page.toPng();
          
          // Decode PNG and encode as highly compressed JPEG
          final image = img.decodeImage(pngBytes);
          if (image != null) {
            final jpegBytes = img.encodeJpg(image, quality: 60);
            
            final pwImage = pw.MemoryImage(jpegBytes);
            compressedPdf.addPage(
              pw.Page(
                pageFormat: p.PdfPageFormat(page.width.toDouble(), page.height.toDouble()),
                margin: pw.EdgeInsets.zero,
                build: (pw.Context context) {
                  return pw.Center(
                    child: pw.Image(pwImage, fit: pw.BoxFit.contain),
                  );
                },
              ),
            );
          }
        }

        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/$customName.pdf';
        await File(path).writeAsBytes(await compressedPdf.save());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Compressed PDF saved! Check Documents tab.')));
          setState(() => _isLoading = false);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error compressing: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: _selectedIndex == 0
              ? AppBar(
                  title: const Text('PDF Master'),
                  actions: [
                    IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
                  ],
                )
              : null,
          body: _buildBody(),
          floatingActionButton: _selectedIndex == 0
              ? FloatingActionButton(
                  onPressed: () => context.push('/scanner'),
                  child: const Icon(Icons.camera_alt),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.folder), label: 'Documents'),
              NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black45,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const DocumentsPage();
      case 2:
        return const SettingsPage();
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Scan anything. Make it digital.',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/scanner'),
                    icon: const Icon(Icons.document_scanner),
                    label: const Text('Scan Document'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );
                      if (result != null && result.files.single.path != null) {
                        if (context.mounted) {
                          context.push('/pdf_viewer', extra: result.files.single.path!);
                        }
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Open PDF'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // We pass the callback to QuickToolsGrid by making it accept a function.
            // Wait, we need to modify QuickToolsGrid to accept the callback. Let's do that next.
            QuickToolsGrid(onToolSelected: _handleToolAction),
          ],
        ),
      ),
    );
  }
}

