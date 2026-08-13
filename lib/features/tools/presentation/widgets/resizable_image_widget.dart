import 'dart:io';
import 'package:flutter/material.dart';

class ResizableImageWidget extends StatefulWidget {
  final String imagePath;
  final double initialWidth;
  final double initialHeight;

  const ResizableImageWidget({
    super.key,
    required this.imagePath,
    this.initialWidth = 200,
    this.initialHeight = 200,
  });

  @override
  State<ResizableImageWidget> createState() => _ResizableImageWidgetState();
}

class _ResizableImageWidgetState extends State<ResizableImageWidget> {
  late double width;
  late double height;
  bool isEditing = false; // Show handles when true

  @override
  void initState() {
    super.initState();
    width = widget.initialWidth;
    height = widget.initialHeight;
  }

  Widget _buildDragHandle(Alignment alignment, {required void Function(DragUpdateDetails) onPanUpdate}) {
    // Only show handles when editing (tapped)
    if (!isEditing) return const SizedBox();
    
    // Determine handle shape based on position
    final isHorizontal = alignment == Alignment.centerLeft || alignment == Alignment.centerRight;
    
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanUpdate: onPanUpdate,
        child: Container(
          width: isHorizontal ? 24 : 40,
          height: isHorizontal ? 40 : 24,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(
            isHorizontal ? Icons.drag_indicator : Icons.drag_handle,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isEditing = !isEditing;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: isEditing ? Border.all(color: Colors.blue, width: 2, style: BorderStyle.solid) : null,
            ),
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.fill, // Allows non-proportional stretching
            ),
          ),
          
          // Right handle
          Positioned(
            right: -12,
            top: height / 2 - 20,
            child: _buildDragHandle(Alignment.centerRight, onPanUpdate: (details) {
              setState(() => width = (width + details.delta.dx * 2).clamp(50.0, 2000.0));
            }),
          ),
          
          // Left handle
          Positioned(
            left: -12,
            top: height / 2 - 20,
            child: _buildDragHandle(Alignment.centerLeft, onPanUpdate: (details) {
              setState(() => width = (width - details.delta.dx * 2).clamp(50.0, 2000.0));
            }),
          ),
          
          // Bottom handle
          Positioned(
            bottom: -12,
            left: width / 2 - 20,
            child: _buildDragHandle(Alignment.bottomCenter, onPanUpdate: (details) {
              setState(() => height = (height + details.delta.dy * 2).clamp(50.0, 2000.0));
            }),
          ),
          
          // Top handle
          Positioned(
            top: -12,
            left: width / 2 - 20,
            child: _buildDragHandle(Alignment.topCenter, onPanUpdate: (details) {
              setState(() => height = (height - details.delta.dy * 2).clamp(50.0, 2000.0));
            }),
          ),
        ],
      ),
    );
  }
}
