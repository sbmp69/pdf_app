import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/pdf_generator.dart';
import '../../../../core/utils/ocr_scanner.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  List<String> _pictures = [];
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _startScan() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return; // User canceled

    setState(() => _isScanning = true);
    try {
      List<XFile> images = [];
      if (source == ImageSource.camera) {
        final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
        if (photo != null) {
          images.add(photo);
        }
      } else {
        images = List.from(await _picker.pickMultiImage());
      }

      if (images.isEmpty) {
        if (!mounted) return;
        setState(() => _isScanning = false);
        return;
      }

      if (!mounted) return;
      
      // Crop each selected image
      List<String> croppedPaths = [];
      for (var img in images) {
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: img.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Document',
              toolbarColor: Theme.of(context).colorScheme.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Crop Document',
            ),
          ],
        );
        if (croppedFile != null) {
          croppedPaths.add(croppedFile.path);
        }
      }

      if (!mounted) return;
      setState(() {
        _pictures.addAll(croppedPaths);
        _isScanning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get or crop pictures: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto start scanner when opening this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanned Documents'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isScanning
          ? const Center(child: CircularProgressIndicator())
          : _pictures.isEmpty
              ? const Center(child: Text('No documents scanned'))
              : ListView.builder(
                  itemCount: _pictures.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Image.file(File(_pictures[index])),
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_pictures.isNotEmpty)
            FloatingActionButton.extended(
              heroTag: 'extract_text',
              onPressed: () async {
                setState(() => _isScanning = true);
                try {
                  String text = '';
                  for (var pic in _pictures) {
                    text += await OcrScanner.extractTextFromImage(pic) + '\n\n';
                  }
                  if (!mounted) return;
                  setState(() => _isScanning = false);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Extracted Text'),
                      content: SingleChildScrollView(child: Text(text)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        )
                      ],
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  setState(() => _isScanning = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('OCR failed: $e')),
                  );
                }
              },
              icon: const Icon(Icons.text_fields),
              label: const Text('Extract Text'),
            ),
          const SizedBox(height: 16),
          if (_pictures.isNotEmpty)
            FloatingActionButton.extended(
              heroTag: 'save_pdf',
              onPressed: () async {
                TextEditingController nameController = TextEditingController(text: 'Scan_${DateTime.now().millisecondsSinceEpoch}');
                
                final String? customName = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Save PDF'),
                      content: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Document Name',
                          suffixText: '.pdf',
                        ),
                        autofocus: true,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
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

                if (customName == null) return; // User canceled

                setState(() => _isScanning = true);
                try {
                  final file = await PdfGenerator.generatePdfFromImages(_pictures, customName);
                  if (!mounted) return;
                  setState(() {
                    _isScanning = false;
                    _pictures.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved successfully! Check Documents tab.')),
                  );
                  context.pop();
                } catch (e) {
                  if (!mounted) return;
                  setState(() => _isScanning = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save PDF: $e')),
                  );
                }
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Save PDF'),
            ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'add_page',
            onPressed: _startScan,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Add Page'),
          ),
        ],
      ),
    );
  }
}
