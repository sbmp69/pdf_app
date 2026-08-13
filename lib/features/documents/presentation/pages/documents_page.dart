import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  List<FileSystemEntity> _pdfFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = directory.listSync().where((file) {
        return file.path.toLowerCase().endsWith('.pdf');
      }).toList();
      
      // Sort by modified date descending (newest first)
      files.sort((a, b) {
        return File(b.path).lastModifiedSync().compareTo(File(a.path).lastModifiedSync());
      });

      setState(() {
        _pdfFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (bytes > 0) ? (bytes.toString().length - 1) ~/ 3 : 0;
    return "${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocuments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pdfFiles.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _loadDocuments,
                  child: ListView.builder(
                    itemCount: _pdfFiles.length,
                    itemBuilder: (context, index) {
                      final file = File(_pdfFiles[index].path);
                      final fileName = file.path.split('/').last.split('\\').last;
                      final fileSize = _formatBytes(file.lengthSync());
                      final lastModified = file.lastModifiedSync();
                      
                      return ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                        title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('$fileSize • ${lastModified.day}/${lastModified.month}/${lastModified.year}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              context.push('/pdf_editor', extra: file.path);
                            } else if (value == 'share') {
                              Share.shareXFiles([XFile(file.path)], text: 'Check out this PDF document.');
                            } else if (value == 'rename') {
                              TextEditingController nameController = TextEditingController(text: fileName.replaceAll('.pdf', ''));
                              final String? newName = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Rename PDF'),
                                  content: TextField(
                                    controller: nameController,
                                    decoration: const InputDecoration(labelText: 'New Name', suffixText: '.pdf'),
                                    autofocus: true,
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                    FilledButton(
                                      onPressed: () {
                                        if (nameController.text.trim().isEmpty) return;
                                        Navigator.pop(context, nameController.text.trim());
                                      },
                                      child: const Text('Rename'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (newName != null) {
                                final String newPath = '${file.parent.path}/$newName.pdf';
                                await file.rename(newPath);
                                _loadDocuments();
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(leading: Icon(Icons.edit_document), title: Text('Edit PDF'), contentPadding: EdgeInsets.zero),
                            ),
                            const PopupMenuItem(
                              value: 'rename',
                              child: ListTile(leading: Icon(Icons.edit), title: Text('Rename'), contentPadding: EdgeInsets.zero),
                            ),
                            const PopupMenuItem(
                              value: 'share',
                              child: ListTile(leading: Icon(Icons.share), title: Text('Share'), contentPadding: EdgeInsets.zero),
                            ),
                          ],
                        ),
                        onTap: () {
                          context.push('/pdf_viewer', extra: file.path);
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/scanner').then((_) => _loadDocuments()),
        child: const Icon(Icons.document_scanner),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No documents yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Scan your first document and it will appear here.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/scanner').then((_) => _loadDocuments()),
            icon: const Icon(Icons.document_scanner),
            label: const Text('Scan Document'),
          ),
        ],
      ),
    );
  }
}
