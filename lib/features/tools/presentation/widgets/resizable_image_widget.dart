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
  late double imgWidth;
  late double imgHeight;
  bool isEditing = true; // Show handles immediately!

  @override
  void initState() {
    super.initState();
    imgWidth = widget.initialWidth;
    imgHeight = widget.initialHeight;
  }

  Widget _buildHandle({required void Function(DragUpdateDetails) onPanUpdate}) {
    if (!isEditing) return const SizedBox();
    return GestureDetector(
      onPanUpdate: onPanUpdate,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade700, width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The total size includes the 12px padding on all sides for the handles.
    final totalWidth = isEditing ? imgWidth + 24 : imgWidth;
    final totalHeight = isEditing ? imgHeight + 24 : imgHeight;
    final offset = isEditing ? 12.0 : 0.0;

    return Listener(
      onPointerDown: (_) {
        if (!isEditing) {
          setState(() => isEditing = true);
        }
      },
      child: SizedBox(
        width: totalWidth,
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Image Box
            Positioned(
              left: offset,
              top: offset,
              width: imgWidth,
              height: imgHeight,
              child: Container(
                decoration: BoxDecoration(
                  border: isEditing ? Border.all(color: Colors.grey.shade700, width: 1) : null,
                ),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            
            // Edge Handles
            if (isEditing) ...[
              // Top Center
              Positioned(
                top: 0,
                left: offset + (imgWidth / 2) - 12,
                child: _buildHandle(onPanUpdate: (details) {
                  setState(() => imgHeight = (imgHeight - details.delta.dy * 2).clamp(20.0, 2000.0));
                }),
              ),
              // Bottom Center
              Positioned(
                bottom: 0,
                left: offset + (imgWidth / 2) - 12,
                child: _buildHandle(onPanUpdate: (details) {
                  setState(() => imgHeight = (imgHeight + details.delta.dy * 2).clamp(20.0, 2000.0));
                }),
              ),
              // Left Center
              Positioned(
                left: 0,
                top: offset + (imgHeight / 2) - 12,
                child: _buildHandle(onPanUpdate: (details) {
                  setState(() => imgWidth = (imgWidth - details.delta.dx * 2).clamp(20.0, 2000.0));
                }),
              ),
              // Right Center
              Positioned(
                right: 0,
                top: offset + (imgHeight / 2) - 12,
                child: _buildHandle(onPanUpdate: (details) {
                  setState(() => imgWidth = (imgWidth + details.delta.dx * 2).clamp(20.0, 2000.0));
                }),
              ),
              
              // Corner Handles
              // Top Left
              Positioned(
                top: 0,
                left: 0,
                child: _buildHandle(onPanUpdate: (details) {
                  setState(() {
                    imgHeight = (imgHeight - details.delta.dy * 2).clamp(20.0, 2000.0);
                    imgWidth = (imgWidth - details.delta.dx * 2).clamp(20.0, 2000.0);
                  });
                }),
              ),
              // Top Right
              Positioned(
                top: 0,
                right: 0,
                child: _buildHandle(onPanUpdate: (details) {
                  setState(() {
                    imgHeight = (imgHeight - details.delta.dy * 2).clamp(20.0, 2000.0);
                    imgWidth = (imgWidth + details.delta.dx * 2).clamp(20.0, 2000.0);
                  });
                }),
              ),
              // Bottom Left
              Positioned(
                bottom: 0,
                left: 0,
                child: _buildHandle(onPanUpdate: (details) {
                  setState(() {
                    imgHeight = (imgHeight + details.delta.dy * 2).clamp(20.0, 2000.0);
                    imgWidth = (imgWidth - details.delta.dx * 2).clamp(20.0, 2000.0);
                  });
                }),
              ),
              // Bottom Right
              Positioned(
                bottom: 0,
                right: 0,
                child: _buildHandle(onPanUpdate: (details) {
                  setState(() {
                    imgHeight = (imgHeight + details.delta.dy * 2).clamp(20.0, 2000.0);
                    imgWidth = (imgWidth + details.delta.dx * 2).clamp(20.0, 2000.0);
                  });
                }),
              ),
              
              // Apply/Done Button to hide handles before export
              Positioned(
                top: 0,
                right: 0, // Placed inside the bounding box so it gets hit tests
                child: GestureDetector(
                  onTap: () {
                    setState(() => isEditing = false);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    margin: const EdgeInsets.only(top: 24, right: 24),
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
