import 'dart:io';
import 'package:flutter/material.dart';

final ValueNotifier<bool> globalIsExportingNotifier = ValueNotifier(false);


class ImageResizeState {
  double width;
  double height;
  double translateX;
  double translateY;
  bool isEditing;

  ImageResizeState({
    required this.width,
    required this.height,
    this.translateX = 0.0,
    this.translateY = 0.0,
    this.isEditing = true,
  });
}

class ResizableImageWidget extends StatefulWidget {
  final String imagePath;
  final ImageResizeState stateData;

  ResizableImageWidget({
    super.key,
    required this.imagePath,
    ImageResizeState? stateData,
  }) : stateData = stateData ?? ImageResizeState(width: 200, height: 200);

  @override
  State<ResizableImageWidget> createState() => _ResizableImageWidgetState();
}

class _ResizableImageWidgetState extends State<ResizableImageWidget> {
  // Drag state
  double _startWidth = 0;
  double _startHeight = 0;
  double _startX = 0;
  double _startY = 0;
  Offset _startPos = Offset.zero;

  void _onPanStart(DragStartDetails details) {
    _startWidth = widget.stateData.width;
    _startHeight = widget.stateData.height;
    _startX = widget.stateData.translateX;
    _startY = widget.stateData.translateY;
    _startPos = details.globalPosition;
  }

  Widget _buildHandle({
    required void Function(DragStartDetails) onPanStart,
    required void Function(DragUpdateDetails) onPanUpdate,
  }) {
    if (!widget.stateData.isEditing) return const SizedBox();
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
  }  @override
  Widget build(BuildContext context) {
    final state = widget.stateData;
    return ValueListenableBuilder<bool>(
      valueListenable: globalIsExportingNotifier,
      builder: (context, isExporting, child) {
        final showHandles = state.isEditing && !isExporting;
        final totalWidth = showHandles ? state.width + 32 : state.width;
        final totalHeight = showHandles ? state.height + 32 : state.height;
        final offset = showHandles ? 16.0 : 0.0;

        return Listener(
          onPointerDown: (_) {
            if (!state.isEditing && !isExporting) {
              setState(() => state.isEditing = true);
            }
          },
          child: Transform.translate(
            offset: Offset(state.translateX, state.translateY),
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
                    width: state.width,
                    height: state.height,
                    child: Container(
                      decoration: BoxDecoration(
                        border: showHandles ? Border.all(color: Colors.grey.shade700, width: 1.5) : null,
                      ),
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  
                  // Edge Handles
                  if (showHandles) ...[
                // Top Center
                Positioned(
                  top: 0,
                  left: offset + (state.width / 2) - 16,
                  child: _buildHandle(
                    onPanStart: _onPanStart,
                    onPanUpdate: (details) {
                      setState(() {
                        final dy = details.globalPosition.dy - _startPos.dy;
                        state.height = (_startHeight - dy).clamp(5.0, 2000.0);
                        final actualDy = state.height - _startHeight;
                        state.translateY = _startY - actualDy / 2;
                      });
                    },
                  ),
                ),
                // Bottom Center
                Positioned(
                  bottom: 0,
                  left: offset + (state.width / 2) - 16,
                  child: _buildHandle(
                    onPanStart: _onPanStart,
                    onPanUpdate: (details) {
                      setState(() {
                        final dy = details.globalPosition.dy - _startPos.dy;
                        state.height = (_startHeight + dy).clamp(5.0, 2000.0);
                        final actualDy = state.height - _startHeight;
                        state.translateY = _startY + actualDy / 2;
                      });
                    },
                  ),
                ),
                // Left Center
                Positioned(
                  left: 0,
                  top: offset + (state.height / 2) - 16,
                  child: _buildHandle(
                    onPanStart: _onPanStart,
                    onPanUpdate: (details) {
                      setState(() {
                        final dx = details.globalPosition.dx - _startPos.dx;
                        state.width = (_startWidth - dx).clamp(5.0, 2000.0);
                        final actualDx = state.width - _startWidth;
                        state.translateX = _startX - actualDx / 2;
                      });
                    },
                  ),
                ),
                // Right Center
                Positioned(
                  right: 0,
                  top: offset + (state.height / 2) - 16,
                  child: _buildHandle(
                    onPanStart: _onPanStart,
                    onPanUpdate: (details) {
                      setState(() {
                        final dx = details.globalPosition.dx - _startPos.dx;
                        state.width = (_startWidth + dx).clamp(5.0, 2000.0);
                        final actualDx = state.width - _startWidth;
                        state.translateX = _startX + actualDx / 2;
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
                        state.width = (_startWidth - dx).clamp(5.0, 2000.0);
                        state.height = (_startHeight - dy).clamp(5.0, 2000.0);
                        state.translateX = _startX - (state.width - _startWidth) / 2;
                        state.translateY = _startY - (state.height - _startHeight) / 2;
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
                        state.width = (_startWidth + dx).clamp(5.0, 2000.0);
                        state.height = (_startHeight - dy).clamp(5.0, 2000.0);
                        state.translateX = _startX + (state.width - _startWidth) / 2;
                        state.translateY = _startY - (state.height - _startHeight) / 2;
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
                        state.width = (_startWidth - dx).clamp(5.0, 2000.0);
                        state.height = (_startHeight + dy).clamp(5.0, 2000.0);
                        state.translateX = _startX - (state.width - _startWidth) / 2;
                        state.translateY = _startY + (state.height - _startHeight) / 2;
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
                        state.width = (_startWidth + dx).clamp(5.0, 2000.0);
                        state.height = (_startHeight + dy).clamp(5.0, 2000.0);
                        state.translateX = _startX + (state.width - _startWidth) / 2;
                        state.translateY = _startY + (state.height - _startHeight) / 2;
                      });
                    },
                  ),
                ),
                
                // Apply/Done Button
                Positioned(
                  top: 0,
                  right: 0,
                  child: Listener(
                    onPointerDown: (_) {
                      setState(() => state.isEditing = false);
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
              ],
            ],
          ),
          ),
        ),
      );
    });
  }
}

