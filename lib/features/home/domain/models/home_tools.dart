import 'package:flutter/material.dart';
import 'tool_item.dart';

final List<ToolItem> allTools = [
  const ToolItem(
    title: 'AI Chat',
    description: 'Chat with your PDF using AI',
    icon: Icons.smart_toy,
    category: ToolCategory.edit,
  ),
  const ToolItem(
    title: 'Scan & Edit PDF',
    description: 'Retype text, add shapes and images',
    icon: Icons.edit_document,
    category: ToolCategory.edit,
    isBeta: true,
  ),
  const ToolItem(
    title: 'Extract & Edit Text',
    description: 'Edit PDF text like a Notepad doc',
    icon: Icons.text_snippet,
    category: ToolCategory.edit,
  ),
  const ToolItem(
    title: 'Merge PDF',
    description: 'Several files in, one out',
    icon: Icons.merge_type,
    category: ToolCategory.optimize,
  ),
  const ToolItem(
    title: 'Compress PDF',
    description: 'Same pages, smaller file',
    icon: Icons.compress,
    category: ToolCategory.optimize,
  ),
  const ToolItem(
    title: 'Protect PDF',
    description: 'Adds a password to open it',
    icon: Icons.lock,
    category: ToolCategory.secure,
  ),
  const ToolItem(
    title: 'Unlock PDF',
    description: 'Needs the current password',
    icon: Icons.lock_open,
    category: ToolCategory.secure,
  ),
  const ToolItem(
    title: 'Apply Watermark',
    description: 'Stamps your mark on every page',
    icon: Icons.branding_watermark,
    category: ToolCategory.edit,
  ),
  const ToolItem(
    title: 'Remove Watermark',
    description: 'Remove watermarks from pages',
    icon: Icons.format_color_reset,
    category: ToolCategory.edit,
  ),
  const ToolItem(
    title: 'Split PDF',
    description: 'Chops one file into several',
    icon: Icons.call_split,
    category: ToolCategory.edit,
  ),
  const ToolItem(
    title: 'Delete Pages',
    description: 'Drops the pages you pick',
    icon: Icons.delete_outline,
    category: ToolCategory.edit,
  ),
  const ToolItem(
    title: 'Reorder Pages',
    description: 'Drag pages into a better order',
    icon: Icons.low_priority,
    category: ToolCategory.edit,
  ),
  const ToolItem(
    title: 'PDF to Word',
    description: 'A Word file; needs real text',
    icon: Icons.description,
    category: ToolCategory.convert,
    isBeta: true,
  ),
  const ToolItem(
    title: 'Word to PDF',
    description: 'Text only, and .docx files only',
    icon: Icons.picture_as_pdf,
    category: ToolCategory.convert,
    isBeta: true,
  ),
  const ToolItem(
    title: 'Repair PDF',
    description: 'Fixes minor issues only',
    icon: Icons.build,
    category: ToolCategory.optimize,
  ),
];
