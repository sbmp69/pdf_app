import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/pdf_generator.dart';

class PdfEditorPage extends StatefulWidget {
  final String? pdfPath;
  const PdfEditorPage({super.key, this.pdfPath});

  @override
  State<PdfEditorPage> createState() => _PdfEditorPageState();
}

class _PdfEditorPageState extends State<PdfEditorPage> {
  bool _isLoading = false;
  List<String> _pageImages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.pdfPath != null) {
        _rasterizePdf(widget.pdfPath!);
      } else {
        _pickFile();
      }
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      await _rasterizePdf(result.files.single.path!);
    } else {
      if (_pageImages.isEmpty && mounted) context.pop();
    }
  }

  Future<void> _rasterizePdf(String pdfPath) async {
    setState(() => _isLoading = true);
    try {
      // Handle content URIs from Intents as well as normal file paths
      final bytes = await File(pdfPath).readAsBytes();
      final directory = await getTemporaryDirectory();
      
      List<String> images = [];
      int pageIndex = 0;
      
      await for (var page in Printing.raster(bytes, dpi: 200)) {
        final imageBytes = await page.toPng();
        final path = '${directory.path}/edit_page_$pageIndex.png';
        await File(path).writeAsBytes(imageBytes);
        images.add(path);
        pageIndex++;
      }
      
      if (!mounted) return;
      setState(() {
        _pageImages = images;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading PDF: $e')));
      if (_pageImages.isEmpty) context.pop();
    }
  }

  Future<void> _openPainter(int index) async {
    final updatedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => ImagePainterScreen(imagePath: _pageImages[index]),
      ),
    );

    if (updatedPath != null) {
      setState(() {
        _pageImages[index] = updatedPath;
      });
    }
  }

  Future<void> _saveFinalPdf() async {
    if (_pageImages.isEmpty) return;
    
    TextEditingController nameController = TextEditingController(text: 'Edited_${DateTime.now().millisecondsSinceEpoch}');
    final String? customName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Edited PDF'),
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
      await PdfGenerator.generatePdfFromImages(_pageImages, customName);
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully! Check Documents tab.')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit PDF Pages'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          if (_pageImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save as PDF',
              onPressed: _saveFinalPdf,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pageImages.isEmpty
              ? const Center(child: Text('No PDF selected'))
              : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Tap on a page to add stickers, draw, or edit.', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: _pageImages.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _openPainter(index),
                            child: Card(
                              elevation: 4,
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Add a unique Key to force image reload if path changes
                                  Image.file(File(_pageImages[index]), fit: BoxFit.cover, key: ValueKey('${_pageImages[index]}_${DateTime.now().millisecondsSinceEpoch}')),
                                  Container(
                                    color: Colors.black.withOpacity(0.1),
                                    child: const Center(
                                      child: Icon(Icons.edit, color: Colors.white, size: 40),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      radius: 12,
                                      child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class ImagePainterScreen extends StatelessWidget {
  final String imagePath;
  const ImagePainterScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ProImageEditor.file(
      File(imagePath),
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: (Uint8List bytes) async {
          final directory = await getTemporaryDirectory();
          final path = '${directory.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png';
          await File(path).writeAsBytes(bytes);
          if (context.mounted) {
            Navigator.pop(context, path);
          }
        },
      ),
      configs: ProImageEditorConfigs(
        designMode: ImageEditorDesignMode.material,
        i18n: const I18n(
          stickerEditor: I18nStickerEditor(
            bottomNavigationBarText: 'Add Image',
          ),
        ),
        tuneEditor: const TuneEditorConfigs(enabled: false),
        filterEditor: const FilterEditorConfigs(enabled: false),
        blurEditor: const BlurEditorConfigs(enabled: false),
        emojiEditor: const EmojiEditorConfigs(enabled: false),
        stickerEditor: StickerEditorConfigs(
          enabled: true,
          builder: (setLayer, scrollController) {
            return Container(
              color: Colors.white,
              child: Center(
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Pick Image from Gallery'),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setLayer(
                        WidgetLayer(
                          widget: SizedBox(
                            width: 200,
                            height: 200,
                            child: Image.file(File(image.path), fit: BoxFit.contain),
                          ),
                          exportConfigs: WidgetLayerExportConfigs(
                            fileUrl: image.path,
                          ),
                        ),
                      );
                      if (context.mounted) Navigator.pop(context); // Close bottom sheet
                    }
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
