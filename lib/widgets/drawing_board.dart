import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/canvas_provider.dart';
import '../models/stroke.dart';
import '../models/note.dart';
import 'stroke_painter.dart';
import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DrawingBoard extends StatefulWidget {
  final CanvasProvider provider;
  const DrawingBoard({super.key, required this.provider});

  @override
  State<DrawingBoard> createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  final TransformationController _transformController = TransformationController();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, child) {
        // ALWAYS enable pan/scale so fingers can scroll the canvas at any time.
        // We use StylusArenaBlockerRecognizer below to prevent standard InteractiveViewer 
        // gestures from absorbing stylus/drawing pointers.
        return InteractiveViewer(
          transformationController: _transformController,
          panEnabled: true, 
          scaleEnabled: true,
          minScale: 0.1,
          maxScale: 5.0,
          boundaryMargin: const EdgeInsets.all(1000), 
          child: SizedBox(
            width: 1000, 
            height: (widget.provider.currentNote.pages.length * 1160.0) + 500,
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.provider.currentNote.pages.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: PageCanvasWidget(
                      pageIndex: index,
                      provider: widget.provider,
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PageCanvasWidget extends StatefulWidget {
  final int pageIndex;
  final CanvasProvider provider;

  const PageCanvasWidget({super.key, required this.pageIndex, required this.provider});

  @override
  State<PageCanvasWidget> createState() => _PageCanvasWidgetState();
}

class _PageCanvasWidgetState extends State<PageCanvasWidget> {

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final page = widget.provider.getPage(widget.pageIndex);
        final activeStroke = widget.provider.activeStrokes[page.id];

        const double pageWidth = 800;
        const double pageHeight = 1131;

        return Container(
          width: pageWidth,
          height: pageHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(5, 5),
              )
            ],
          ),
          child: RawGestureDetector(
            gestures: {
              StylusArenaBlockerRecognizer: GestureRecognizerFactoryWithHandlers<StylusArenaBlockerRecognizer>(
                () => StylusArenaBlockerRecognizer(provider: widget.provider),
                (StylusArenaBlockerRecognizer instance) {
                  instance.provider = widget.provider;
                },
              ),
            },
            child: Listener(
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              child: ClipRect(
              child: Stack(
                children: [
                   _buildBackground(pageWidth, pageHeight),
                  
                  for (var layer in page.layers.reversed)
                    if (layer.isVisible)
                      RepaintBoundary(
                        child: IgnorePointer(
                          ignoring: true, // Strokes shouldn't block hits to items below
                          child: CustomPaint(
                            painter: StrokePainter(layer.strokes, widget.provider.activeTool),
                            size: const Size(pageWidth, pageHeight),
                          ),
                        ),
                      ),
                      
                  if (activeStroke != null)
                    RepaintBoundary(
                      child: IgnorePointer(
                        ignoring: true,
                        child: CustomPaint(
                          painter: StrokePainter([activeStroke], widget.provider.activeTool),
                          size: const Size(pageWidth, pageHeight),
                        ),
                      ),
                    ),

                  // Important: Items (images/labels) must be at the TOP of the stack to receive gestures
                  for (var item in page.items)
                    _buildCanvasItem(item),
                  
                  if (widget.provider.activeTool == ToolType.eraser && widget.provider.currentPointer != null)
                    RepaintBoundary(
                      child: IgnorePointer(
                        ignoring: true,
                        child: CustomPaint(
                          painter: EraserCursorPainter(widget.provider.currentPointer!, widget.provider.eraserWidth),
                          size: const Size(pageWidth, pageHeight),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  void _handlePointerDown(PointerEvent event) {
    if (_isDrawingDevice(event.kind)) {
       RenderBox box = context.findRenderObject() as RenderBox;
       Offset localOffset = box.globalToLocal(event.position);
       widget.provider.updateCurrentPointer(localOffset);
       
       if (widget.provider.activeTool == ToolType.select) {
          // Toggle tape ONLY in select mode
          widget.provider.tryToggleTape(widget.pageIndex, localOffset);
          return;
       }

       if (widget.provider.activeTool == ToolType.lasso) {
          widget.provider.clearSelection();
       }
       
       widget.provider.addPoint(widget.pageIndex, localOffset, event.pressure);
    }
  }

  void _handlePointerMove(PointerEvent event) {
    if (_isDrawingDevice(event.kind)) {
      RenderBox box = context.findRenderObject() as RenderBox;
      Offset localOffset = box.globalToLocal(event.position);
      widget.provider.updateCurrentPointer(localOffset);

      if (widget.provider.activeTool == ToolType.select) return;

      widget.provider.addPoint(widget.pageIndex, localOffset, event.pressure);
    }
  }

  void _handlePointerUp(PointerEvent event) {
    if (_isDrawingDevice(event.kind)) {
      widget.provider.updateCurrentPointer(null);
      if (widget.provider.activeTool == ToolType.select) return;
      widget.provider.endStroke(widget.pageIndex);
    }
  }
  
  bool _isDrawingDevice(PointerDeviceKind kind) {
    return kind == PointerDeviceKind.stylus || 
           kind == PointerDeviceKind.invertedStylus || 
           kind == PointerDeviceKind.mouse ||
           (kind == PointerDeviceKind.touch && widget.provider.drawWithFinger); 
  }

  Widget _buildCanvasItem(CanvasItem item) {
    return Positioned(
      left: item.x,
      top: item.y,
      width: item.width,
      height: item.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          widget.provider.isInteractingWithItem = true;
        },
        onPanUpdate: (details) {
          if (!item.isLocked) {
            widget.provider.updateCanvasItemPosition(item, details.delta);
          }
        },
        onPanEnd: (_) => widget.provider.isInteractingWithItem = false,
        onPanCancel: () => widget.provider.isInteractingWithItem = false,
        onLongPressStart: (details) {
          _showItemContextMenu(context, item, details.globalPosition);
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item is TextItem ? Colors.white.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: item.isLocked ? Colors.red.withOpacity(0.3) : (widget.provider.isInteractingWithItem ? Colors.blueAccent.withOpacity(0.3) : Colors.transparent),
              width: 1.5,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (item is ImageItem)
                SizedBox.expand(child: Image.memory(item.imageBytes, fit: BoxFit.cover))
              else if (item is TextItem)
                SingleChildScrollView(child: Text(item.text, style: TextStyle(fontSize: item.fontSize, color: Colors.blueGrey.shade800)))
              else if (item is AudioItem)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.mic, color: Colors.blueAccent, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(item.durationSeconds ~/ 60).toString().padLeft(2, '0')}:${(item.durationSeconds % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        widget.provider.playingAudioId == item.id ? Icons.stop_circle : Icons.play_circle_filled,
                        color: Colors.blueAccent,
                        size: 32,
                      ),
                      onPressed: () => widget.provider.playAudio(item.id),
                    ),
                  ],
                ),
              
              if (item.isLocked)
                const Positioned(top: 0, right: 0, child: Icon(Icons.lock, size: 12, color: Colors.red)),

              // RESIZE HANDLE
              if (!item.isLocked && widget.provider.activeTool == ToolType.select)
                Positioned(
                  right: -12, bottom: -12,
                  child: GestureDetector(
                    onPanUpdate: (details) => widget.provider.updateCanvasItemSize(item, details.delta),
                    onPanEnd: (_) => widget.provider.saveHistory(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                      child: const Icon(Icons.open_in_full, size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemContextMenu(BuildContext context, CanvasItem item, Offset position) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: Icon(item.isLocked ? Icons.lock_open : Icons.lock),
            title: Text(item.isLocked ? 'Unlock' : 'Lock Position'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => widget.provider.toggleCanvasItemLock(item),
        ),
        if (item is ImageItem)
          PopupMenuItem(
            child: const ListTile(
              leading: Icon(Icons.crop),
              title: Text('Crop Image'),
              contentPadding: EdgeInsets.zero,
            ),
            onTap: () async {
               Navigator.pop(context);
               if (kIsWeb) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image Cropping mode is currently only available on Desktop/Mobile.')));
                  return;
               }
               final tempFile = await _writeBytesToTempFile(item.imageBytes);
               final croppedFile = await ImageCropper().cropImage(
                 sourcePath: tempFile.path,
                 aspectRatioPresets: [
                   CropAspectRatioPreset.square,
                   CropAspectRatioPreset.ratio3x2,
                   CropAspectRatioPreset.original,
                   CropAspectRatioPreset.ratio4x3,
                   CropAspectRatioPreset.ratio16x9
                 ],
                 uiSettings: [
                   AndroidUiSettings(
                     toolbarTitle: 'Cropper',
                     toolbarColor: Colors.deepOrange,
                     toolbarWidgetColor: Colors.white,
                     initAspectRatio: CropAspectRatioPreset.original,
                     lockAspectRatio: false
                   ),
                   IOSUiSettings(
                     title: 'Cropper',
                   ),
                 ],
               );
               if (croppedFile != null) {
                  final newBytes = await croppedFile.readAsBytes();
                  // Decode to get new true dimensions
                  ui.decodeImageFromList(newBytes, (ui.Image img) {
                     widget.provider.updateImageCropped(item, newBytes, img.width.toDouble(), img.height.toDouble());
                  });
               }
            },
          ),
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.copy),
            title: Text('Duplicate'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => widget.provider.duplicateCanvasItem(widget.pageIndex, item),
        ),
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => widget.provider.deleteCanvasItem(widget.pageIndex, item),
        ),
      ],
    );
  }

  Future<dynamic> _writeBytesToTempFile(Uint8List bytes) async {
    if (kIsWeb) return null;
    final tempDir = io.Directory.systemTemp;
    final file = io.File('${tempDir.path}/crop_${DateTime.now().millisecondsSinceEpoch}.png');
    return await file.writeAsBytes(bytes);
  }

  Widget _buildBackground(double width, double height) {
    var page = widget.provider.getPage(widget.pageIndex);
    if (page.pdfBytes != null) {
      return SizedBox(
        width: width,
        height: height,
        child: IgnorePointer(
          child: SfPdfViewer.memory(
            page.pdfBytes!,
            canShowScrollHead: false,
            canShowScrollStatus: false,
            canShowPaginationDialog: false,
            initialZoomLevel: 1.0,
            enableDoubleTapZooming: false,
            interactionMode: PdfInteractionMode.pan,
          ),
        ),
      );
    }
    
    final template = widget.provider.currentNote.backgroundTemplate;
    final paperColorName = widget.provider.currentNote.paperColor;
    
    Color backgroundColor;
    switch (paperColorName) {
      case 'gray': backgroundColor = Colors.grey.shade300; break;
      case 'beige': backgroundColor = const Color(0xFFF5F5DC); break;
      case 'kraft': backgroundColor = const Color(0xFFC4A484); break;
      case 'black': backgroundColor = const Color(0xFF1A1A1A); break;
      default: backgroundColor = Colors.white;
    }

    if (template == 'blank') return Container(color: backgroundColor);
    
    return Container(
      color: backgroundColor,
      child: CustomPaint(
        painter: GridPainter(template, paperColorName),
        size: Size(width, height),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final String template;
  final String paperColor;
  GridPainter(this.template, this.paperColor);

  @override
  void paint(Canvas canvas, Size size) {
    final lineColor = paperColor == 'black' ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.3);
    final paint = Paint()..color = lineColor..strokeWidth = 1.0;
    
    if (template == 'lines') {
       for(double y = 80; y < size.height; y += 40) {
         canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
       }
    } else if (template == 'grid') {
       for(double y = 0; y < size.height; y += 40) {
         canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
       }
       for(double x = 0; x < size.width; x += 40) {
         canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
       }
    }
  }
  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => oldDelegate.template != template || oldDelegate.paperColor != paperColor;
}

class EraserCursorPainter extends CustomPainter {
  final Offset position;
  final double width;

  EraserCursorPainter(this.position, this.width);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawCircle(position, width / 2, paint);
    canvas.drawCircle(position, width / 2, borderPaint);
  }

  @override
  bool shouldRepaint(covariant EraserCursorPainter oldDelegate) {
    return oldDelegate.position != position || oldDelegate.width != width;
  }
}

class StylusArenaBlockerRecognizer extends OneSequenceGestureRecognizer {
  CanvasProvider provider;

  StylusArenaBlockerRecognizer({required this.provider});

  @override
  void addPointer(PointerDownEvent event) {
    bool isDrawingTool = provider.activeTool == ToolType.pen || 
                         provider.activeTool == ToolType.highlighter || 
                         provider.activeTool == ToolType.eraser ||
                         provider.activeTool == ToolType.lasso;

    bool isDrawingDevice = event.kind == PointerDeviceKind.stylus || 
                           event.kind == PointerDeviceKind.invertedStylus || 
                           event.kind == PointerDeviceKind.mouse ||
                           (event.kind == PointerDeviceKind.touch && provider.drawWithFinger);

    if (isDrawingTool && isDrawingDevice) {
       startTrackingPointer(event.pointer);
       resolve(GestureDisposition.accepted); // Win the arena to block InteractiveViewer
    } else {
       resolve(GestureDisposition.rejected); // Let InteractiveViewer or items handle it
    }
  }

  @override
  void handleEvent(PointerEvent event) {
     if (event is PointerUpEvent || event is PointerCancelEvent) {
        stopTrackingPointer(event.pointer);
     }
  }

  @override
  String get debugDescription => 'StylusBlocker';
  
  @override
  void didStopTrackingLastPointer(int pointer) {}
}
