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
  double translateX = 0.0;
  double translateY = 0.0;
  bool isEditing = true;

  // Drag state
  double _startWidth = 0;
  double _startHeight = 0;
  double _startX = 0;
  double _startY = 0;
  Offset _startPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    imgWidth = widget.initialWidth;
    imgHeight = widget.initialHeight;
  }

  void _onPanStart(DragStartDetails details) {
    _startWidth = imgWidth;
    _startHeight = imgHeight;
    _startX = translateX;
    _startY = translateY;
    _startPos = details.globalPosition;
  }

  Widget _buildHandle({
    required void Function(DragStartDetails) onPanStart,
    required void Function(DragUpdateDetails) onPanUpdate,
  }) {
    if (!isEditing) return const SizedBox();
    return GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32, // Increased hit area for easier grabbing
        height: 32,
        alignment: Alignment.center,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade700, width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth = isEditing ? imgWidth + 32 : imgWidth;
    final totalHeight = isEditing ? imgHeight + 32 : imgHeight;
    final offset = isEditing ? 16.0 : 0.0;

    return Listener(
      onPointerDown: (_) {
        if (!isEditing) {
          setState(() => isEditing = true);
        }
      },
      child: Transform.translate(
        offset: Offset(translateX, translateY),
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
                    border: isEditing ? Border.all(color: Colors.grey.shade700, width: 1.5) : null,
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
                  left: offset + (imgWidth / 2) - 16,
                  child: _buildHandle(
                    onPanStart: _onPanStart,
                    onPanUpdate: (details) {
                      setState(() {
                        final dy = details.globalPosition.dy - _startPos.dy;
                        imgHeight = (_startHeight - dy).clamp(5.0, 2000.0);
                        final actualDy = imgHeight - _startHeight;
                        translateY = _startY - actualDy / 2;
                      });
                    },
                  ),
                ),
                // Bottom Center
                Positioned(
                  bottom: 0,
                  left: offset + (imgWidth / 2) - 16,
                  child: _buildHandle(
                    onPanStart: _onPanStart,
                    onPanUpdate: (details) {
                      setState(() {
                        final dy = details.globalPosition.dy - _startPos.dy;
                        imgHeight = (_startHeight + dy).clamp(5.0, 2000.0);
                        final actualDy = imgHeight - _startHeight;
                        translateY = _startY + actualDy / 2;
                      });
                    },
                  ),
                ),
                // Left Center
                Positioned(
                  left: 0,
                  top: offset + (imgHeight / 2) - 16,
                  child: _buildHandle(
                    onPanStart: _onPanStart,
                    onPanUpdate: (details) {
                      setState(() {
                        final dx = details.globalPosition.dx - _startPos.dx;
                        imgWidth = (_startWidth - dx).clamp(5.0, 2000.0);
                        final actualDx = imgWidth - _startWidth;
                        translateX = _startX - actualDx / 2;
                      });
                    },
                  ),
                ),
                // Right Center
                Positioned(
                  right: 0,
                  top: offset + (imgHeight / 2) - 16,
                  child: _buildHandle(
                    onPanStart: _onPanStart,
                    onPanUpdate: (details) {
                      setState(() {
                        final dx = details.globalPosition.dx - _startPos.dx;
                        imgWidth = (_startWidth + dx).clamp(5.0, 2000.0);
                        final actualDx = imgWidth - _startWidth;
                        translateX = _startX + actualDx / 2;
                      });
                    },
                  ),
                ),
                
                // Corner Handles
                // Top Left
                Positioned(
                  top: 0,
                  left: 0,
                  child: _buildHandle(
                    onPanStart: _onPanStart,
                    onPanUpdate: (details) {
                      setState(() {
                        final dx = details.globalPosition.dx - _startPos.dx;
                        final dy = details.globalPosition.dy - _startPos.dy;
                        imgWidth = (_startWidth - dx).clamp(5.0, 2000.0);
                        imgHeight = (_startHeight - dy).clamp(5.0, 2000.0);
                        translateX = _startX - (imgWidth - _startWidth) / 2;
                        translateY = _startY - (imgHeight - _startHeight) / 2;
                      });
                    },
                  ),
                ),
                // Top Right
                Positioned(
                  top: 0,
                  right: 0,
                  child: _buildHandle(
                    onPanStart: _onPanStart,
                    onPanUpdate: (details) {
                      setState(() {
                        final dx = details.globalPosition.dx - _startPos.dx;
                        final dy = details.globalPosition.dy - _startPos.dy;
                        imgWidth = (_startWidth + dx).clamp(5.0, 2000.0);
                        imgHeight = (_startHeight - dy).clamp(5.0, 2000.0);
                        translateX = _startX + (imgWidth - _startWidth) / 2;
                        translateY = _startY - (imgHeight - _startHeight) / 2;
                      });
                    },
                  ),
                ),
                // Bottom Left
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: _buildHandle(
                    onPanStart: _onPanStart,
                    onPanUpdate: (details) {
                      setState(() {
                        final dx = details.globalPosition.dx - _startPos.dx;
                        final dy = details.globalPosition.dy - _startPos.dy;
                        imgWidth = (_startWidth - dx).clamp(5.0, 2000.0);
                        imgHeight = (_startHeight + dy).clamp(5.0, 2000.0);
                        translateX = _startX - (imgWidth - _startWidth) / 2;
                        translateY = _startY + (imgHeight - _startHeight) / 2;
                      });
                    },
                  ),
                ),
                // Bottom Right
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _buildHandle(
                    onPanStart: _onPanStart,
                    onPanUpdate: (details) {
                      setState(() {
                        final dx = details.globalPosition.dx - _startPos.dx;
                        final dy = details.globalPosition.dy - _startPos.dy;
                        imgWidth = (_startWidth + dx).clamp(5.0, 2000.0);
                        imgHeight = (_startHeight + dy).clamp(5.0, 2000.0);
                        translateX = _startX + (imgWidth - _startWidth) / 2;
                        translateY = _startY + (imgHeight - _startHeight) / 2;
                      });
                    },
                  ),
                ),
                
                // Apply/Done Button
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => isEditing = false);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: const EdgeInsets.only(top: 32, right: 32),
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
