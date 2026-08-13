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

  Widget _buildHandle({required void Function(DragUpdateDetails) onPanUpdate}) {
    if (!isEditing) return const SizedBox();
    return GestureDetector(
      onPanUpdate: onPanUpdate,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade700, width: 1.5),
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
              border: isEditing ? Border.all(color: Colors.grey.shade700, width: 1) : null,
            ),
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.fill,
            ),
          ),
          
          // Edge Handles
          if (isEditing) ...[
            // Top Center
            Positioned(
              top: -6,
              left: width / 2 - 6,
              child: _buildHandle(onPanUpdate: (details) {
                setState(() => height = (height - details.delta.dy * 2).clamp(20.0, 2000.0));
              }),
            ),
            // Bottom Center
            Positioned(
              bottom: -6,
              left: width / 2 - 6,
              child: _buildHandle(onPanUpdate: (details) {
                setState(() => height = (height + details.delta.dy * 2).clamp(20.0, 2000.0));
              }),
            ),
            // Left Center
            Positioned(
              left: -6,
              top: height / 2 - 6,
              child: _buildHandle(onPanUpdate: (details) {
                setState(() => width = (width - details.delta.dx * 2).clamp(20.0, 2000.0));
              }),
            ),
            // Right Center
            Positioned(
              right: -6,
              top: height / 2 - 6,
              child: _buildHandle(onPanUpdate: (details) {
                setState(() => width = (width + details.delta.dx * 2).clamp(20.0, 2000.0));
              }),
            ),
            
            // Corner Handles
            // Top Left
            Positioned(
              top: -6,
              left: -6,
              child: _buildHandle(onPanUpdate: (details) {
                setState(() {
                  height = (height - details.delta.dy * 2).clamp(20.0, 2000.0);
                  width = (width - details.delta.dx * 2).clamp(20.0, 2000.0);
                });
              }),
            ),
            // Top Right
            Positioned(
              top: -6,
              right: -6,
              child: _buildHandle(onPanUpdate: (details) {
                setState(() {
                  height = (height - details.delta.dy * 2).clamp(20.0, 2000.0);
                  width = (width + details.delta.dx * 2).clamp(20.0, 2000.0);
                });
              }),
            ),
            // Bottom Left
            Positioned(
              bottom: -6,
              left: -6,
              child: _buildHandle(onPanUpdate: (details) {
                setState(() {
                  height = (height + details.delta.dy * 2).clamp(20.0, 2000.0);
                  width = (width - details.delta.dx * 2).clamp(20.0, 2000.0);
                });
              }),
            ),
            // Bottom Right
            Positioned(
              bottom: -6,
              right: -6,
              child: _buildHandle(onPanUpdate: (details) {
                setState(() {
                  height = (height + details.delta.dy * 2).clamp(20.0, 2000.0);
                  width = (width + details.delta.dx * 2).clamp(20.0, 2000.0);
                });
              }),
            ),
          ]
        ],
      ),
    );
  }
}
