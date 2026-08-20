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
import '../../domain/models/tool_item.dart';
import '../../domain/models/home_tools.dart';
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
  String _searchQuery = '';
  ToolCategory? _selectedCategory; // null means 'All'

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
      case 'Scan & Edit PDF':
        context.push('/pdf_editor');
        break;
      case 'AI Chat':
        await _aiChat();
        break;
      case 'Unlock PDF':
        await _unlockPdf();
        break;
      case 'Repair PDF':
        await _repairPdf();
        break;
      case 'Split PDF':
        await _pickAndRoute('/split_pdf');
        break;
      case 'Delete Pages':
        await _pickAndRoute('/delete_pages');
        break;
      case 'Reorder Pages':
        await _pickAndRoute('/reorder_pages');
        break;
      case 'Remove Watermark':
        await _pickAndRoute('/remove_watermark');
        break;
      case 'Apply Watermark':
        await _pickAndRoute('/apply_watermark');
        break;
      case 'Extract & Edit Text':
        await _pickAndRoute('/extract_rebuild_editor');
        break;
      default:
        // Handle unimplemented tools safely
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$action is coming soon!')),
          );
        }
        break;
    }
  }

  Future<void> _pickAndRoute(String routeName) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      if (mounted) {
        context.push(routeName, extra: result.files.single.path!);
      }
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

  Future<void> _unlockPdf() async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      TextEditingController passController = TextEditingController();
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unlock PDF'),
          content: TextField(
            controller: passController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current Password'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (passController.text.isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Unlock'),
            ),
          ],
        ),
      );

      if (proceed != true) return;

      setState(() => _isLoading = true);
      try {
        final bytes = await File(result.files.single.path!).readAsBytes();
        
        // This will throw if password is wrong
        final doc = PdfDocument(inputBytes: bytes, password: passController.text);
        
        // To completely strip security, we create a new document and copy pages.
        // Syncfusion's security properties cannot be fully "deleted" once set on an existing loaded document.
        final newDoc = PdfDocument();
        for (int i = 0; i < doc.pages.count; i++) {
          final template = doc.pages[i].createTemplate();
          final page = newDoc.pages.add();
          page.graphics.drawPdfTemplate(template, const Offset(0, 0));
        }
        
        final List<int> savedBytes = newDoc.saveSync();
        newDoc.dispose();
        doc.dispose();

        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/Unlocked_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await File(path).writeAsBytes(savedBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Unlocked successfully!')));
          setState(() => _selectedIndex = 1);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error unlocking: Incorrect password or invalid file.')));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _repairPdf() async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() => _isLoading = true);
      try {
        final bytes = await File(result.files.single.path!).readAsBytes();
        
        // Loading and immediately saving a document in Syncfusion rebuilds the XREF table,
        // which fixes many common corruption issues (like truncated streams).
        final doc = PdfDocument(inputBytes: bytes);
        
        final newDoc = PdfDocument();
        for (int i = 0; i < doc.pages.count; i++) {
          final template = doc.pages[i].createTemplate();
          final page = newDoc.pages.add();
          page.graphics.drawPdfTemplate(template, const Offset(0, 0));
        }
        
        final List<int> savedBytes = newDoc.saveSync();
        newDoc.dispose();
        doc.dispose();

        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/Repaired_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await File(path).writeAsBytes(savedBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Repaired and saved!')));
          setState(() => _selectedIndex = 1);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not repair PDF: File is too severely damaged.')));
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
    List<ToolItem> filteredTools = allTools.where((tool) {
      final matchesSearch = tool.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            tool.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == null || tool.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      children: [
        // Security Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.green.withOpacity(0.1),
          child: Row(
            children: [
              const Icon(Icons.security, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Files stay on this device',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(Icons.lock, color: Colors.grey, size: 16),
            ],
          ),
        ),
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Smart search tools...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        // Category Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildCategoryChip('All', null),
              const SizedBox(width: 8),
              _buildCategoryChip('Edit', ToolCategory.edit),
              const SizedBox(width: 8),
              _buildCategoryChip('Optimize', ToolCategory.optimize),
              const SizedBox(width: 8),
              _buildCategoryChip('Convert', ToolCategory.convert),
              const SizedBox(width: 8),
              _buildCategoryChip('Secure', ToolCategory.secure),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tools List
        Expanded(
          child: ListView.separated(
            itemCount: filteredTools.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tool = filteredTools[index];
              return ListTile(
                onTap: () => _handleToolAction(tool.title),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(tool.icon, color: Theme.of(context).colorScheme.primary),
                ),
                title: Row(
                  children: [
                    Text(tool.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (tool.isBeta) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('BETA', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ]
                  ],
                ),
                subtitle: Text(tool.description, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, ToolCategory? category) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedCategory = category);
        } else if (category != null) {
          setState(() => _selectedCategory = null); // Unselecting a specific tab goes back to All
        }
      },
      showCheckmark: false,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

