import 'package:flutter/material.dart';

enum ToolCategory {
  edit,
  optimize,
  convert,
  secure
}

class ToolItem {
  final String title;
  final String description;
  final IconData icon;
  final ToolCategory category;
  final bool isBeta;

  const ToolItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    this.isBeta = false,
  });
}
