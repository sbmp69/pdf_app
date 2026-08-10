import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickToolsGrid extends StatelessWidget {
  const QuickToolsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'SCAN'),
        const SizedBox(height: 12),
        _buildGrid(context, [
          _ToolItem('Camera Scanner', Icons.document_scanner),
          _ToolItem('Batch Scanner', Icons.file_copy),
          _ToolItem('ID Card', Icons.badge),
          _ToolItem('Passport', Icons.book_online),
          _ToolItem('Receipt', Icons.receipt_long),
          _ToolItem('Business Card', Icons.contact_mail),
        ]),
        const SizedBox(height: 24),
        _buildSectionTitle(context, 'CREATE'),
        const SizedBox(height: 12),
        _buildGrid(context, [
          _ToolItem('Images → PDF', Icons.image),
          _ToolItem('Text → PDF', Icons.text_snippet),
          _ToolItem('QR Code', Icons.qr_code),
        ]),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.2,
          ),
    );
  }

  Widget _buildGrid(BuildContext context, List<_ToolItem> tools) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tools.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final tool = tools[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (tool.title == 'QR Code') {
                context.push('/qr_scanner');
              } else {
                context.push('/scanner');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tool.icon, size: 32, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    tool.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToolItem {
  final String title;
  final IconData icon;

  _ToolItem(this.title, this.icon);
}
