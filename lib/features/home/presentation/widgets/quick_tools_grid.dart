import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickToolsGrid extends StatelessWidget {
  final Function(String) onToolSelected;

  const QuickToolsGrid({super.key, required this.onToolSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'PDF TOOLS'),
        const SizedBox(height: 12),
        _buildGrid(context, [
          _ToolItem('Merge PDF', Icons.merge_type),
          _ToolItem('Compress PDF', Icons.compress),
          _ToolItem('Protect PDF', Icons.lock),
          _ToolItem('Edit PDF', Icons.edit_document),
          _ToolItem('AI Chat', Icons.smart_toy),
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
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        final tool = tools[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onToolSelected(tool.title),
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
                          fontSize: 14,
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
