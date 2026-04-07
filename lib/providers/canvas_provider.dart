import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/stroke.dart';
import '../models/layer.dart';
import '../models/note.dart';

class CanvasProvider extends ChangeNotifier {
  Note currentNote;
  
  int activePageIndex = 0;
  int activeLayerIndex = 0;
  
  ToolType activeTool = ToolType.pen;
  EraserType eraserType = EraserType.object;
  
  // Pen settings
  double penThinning = 0.6; // 0.6 for Fountain, 0.0 for Ballpoint
  
  // Quick Slots
  List<Color> presetColors = [Colors.black, Colors.blueAccent, Colors.redAccent];
  int activeColorSlot = 0;
  
  List<double> presetWidths = [2.0, 4.0, 8.0];
  int activeWidthSlot = 0;
  
  Color get activeColor => presetColors[activeColorSlot];
  double get activeWidth => presetWidths[activeWidthSlot];
  
  double eraserWidth = 30.0;
  List<Color> recentColors = [Colors.black, Colors.blueAccent, Colors.redAccent];
  Offset? currentPointer;

  bool _isToolbarVisible = true;
  bool get isToolbarVisible => _isToolbarVisible;
  
  bool isInteractingWithItem = false;
  
  bool drawWithFinger = false;
  
  void toggleDrawWithFinger() {
    drawWithFinger = !drawWithFinger;
    notifyListeners();
  }
  
  bool _isLayerPanelVisible = false;
  bool get isLayerPanelVisible => _isLayerPanelVisible;

  bool _isPageManagerVisible = false;
  bool get isPageManagerVisible => _isPageManagerVisible;

  // --- Undo / Redo ---
  final List<Note> _undoStack = [];
  final List<Note> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void saveHistory() {
    _undoStack.add(currentNote.copy());
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    _redoStack.clear();
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    _redoStack.add(currentNote.copy());
    currentNote = _undoStack.removeLast();
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(currentNote.copy());
    currentNote = _redoStack.removeLast();
    notifyListeners();
  }

  // --- Recording ---
  bool isRecording = false;

  void toggleRecording() {
    if (!isRecording) {
      isRecording = true;
    } else {
      isRecording = false;
      addAudioItem(activePageIndex, 45); // mocked
    }
    notifyListeners();
  }

  Map<String, Stroke?> activeStrokes = {};
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? playingAudioId;
  
  CanvasProvider({required this.currentNote});

  PageData getPage(int index) => currentNote.pages[index];
  
  LayerData getActiveLayer(int pageIndex) {
    if (activeLayerIndex >= currentNote.pages[pageIndex].layers.length) {
      return currentNote.pages[pageIndex].layers.last; 
    }
    return currentNote.pages[pageIndex].layers[activeLayerIndex];
  }

  void toggleToolbar() {
    _isToolbarVisible = !_isToolbarVisible;
    notifyListeners();
  }

  void toggleLayerPanel() {
    _isLayerPanelVisible = !_isLayerPanelVisible;
    if (_isLayerPanelVisible) _isPageManagerVisible = false;
    notifyListeners();
  }

  void showPageManager() {
    _isPageManagerVisible = true;
    _isLayerPanelVisible = false;
    notifyListeners();
  }

  void hidePageManager() {
    _isPageManagerVisible = false;
    notifyListeners();
  }

  void loadNote(Note note) {
    currentNote = note;
    _isLayerPanelVisible = false;
    _isPageManagerVisible = false;
    notifyListeners();
  }

  void setActiveTool(ToolType tool) {
    if (activeTool == tool) {
       activeTool = ToolType.select;
    } else {
       activeTool = tool;
    }
    notifyListeners();
  }

  void setActiveColorSlot(int index) {
    activeColorSlot = index;
    notifyListeners();
  }

  void updateColorSlot(int index, Color color) {
    presetColors[index] = color;
    activeColorSlot = index;
    notifyListeners();
  }

  void setActiveWidthSlot(int index) {
    activeWidthSlot = index;
    notifyListeners();
  }

  void updateWidthSlot(int index, double width) {
    presetWidths[index] = width;
    activeWidthSlot = index;
    notifyListeners();
  }

  void setActiveColor(Color color) {
    // Legacy support: update current slot
    updateColorSlot(activeColorSlot, color);
  }

  void addRecentColor(Color color) {
    if (!recentColors.contains(color)) {
      recentColors.insert(0, color);
      if (recentColors.length > 5) recentColors.removeLast();
      notifyListeners();
    }
  }

  void setActiveWidth(double width) {
    if (activeTool == ToolType.eraser) {
      eraserWidth = width;
    } else {
      updateWidthSlot(activeWidthSlot, width);
    }
    notifyListeners();
  }

  void setPaperColor(String color) {
    currentNote.paperColor = color;
    notifyListeners();
  }

  void setBackgroundTemplate(String template) {
    currentNote.backgroundTemplate = template;
    notifyListeners();
  }

  void updateCurrentPointer(Offset? offset) {
    currentPointer = offset;
    notifyListeners();
  }

  void clearSelection() {
    for (var page in currentNote.pages) {
      for (var layer in page.layers) {
        for (var stroke in layer.strokes) {
          stroke.isSelected = false;
          stroke.transformOffset = Offset.zero;
        }
      }
    }
    notifyListeners();
  }

  void addPoint(int pageIndex, Offset point, double pressure) {
    if (activeTool == ToolType.eraser) {
       _handleEraser(pageIndex, point);
       return;
    }
    
    final pageId = currentNote.pages[pageIndex].id;
    if (activeStrokes[pageId] == null) {
      activeStrokes[pageId] = Stroke(
        id: DateTime.now().toString(),
        color: activeTool == ToolType.highlighter ? activeColor.withOpacity(0.3) : activeColor,
        strokeWidth: activeTool == ToolType.highlighter ? activeWidth * 2 : activeWidth,
        toolType: activeTool,
        points: [PointData(point, pressure)],
        penThinning: penThinning,
      );
    } else {
      activeStrokes[pageId]!.points.add(PointData(point, pressure));
      activeStrokes[pageId]!.invalidatePath();
    }
    notifyListeners();
  }

  void _handleEraser(int pageIndex, Offset point) {
    final layer = getActiveLayer(pageIndex);
    if (eraserType == EraserType.object) {
       // Object eraser: remove entire stroke if point is within bounds
       layer.strokes.removeWhere((s) => s.intersectsRect(Rect.fromCircle(center: point, radius: eraserWidth/2)));
    } else {
       // Pixel eraser: Simplified for prototype - similar to object
       layer.strokes.removeWhere((s) {
         if (s.toolType == ToolType.tape) return false; 
         return s.intersectsRect(Rect.fromCircle(center: point, radius: eraserWidth / 4));
       });
    }
    notifyListeners();
  }

  bool tryToggleTape(int pageIndex, Offset point) {
    // Check if we hit a tape to reveal/hide it
    final page = currentNote.pages[pageIndex];
    for (var layer in page.layers.reversed) {
      if (layer.isLocked || !layer.isVisible) continue;
      for (var stroke in layer.strokes.reversed) {
        if (stroke.toolType == ToolType.tape) {
          // Increase hitbox for tape toggling
          if (stroke.intersectsRect(Rect.fromCircle(center: point, radius: 20))) {
            stroke.isTapeHidden = !stroke.isTapeHidden;
            notifyListeners();
            return true;
          }
        }
      }
    }
    return false;
  }

  void endStroke(int pageIndex) {
    saveHistory(); // Save before finishing stroke
    final pageId = currentNote.pages[pageIndex].id;
    final stroke = activeStrokes[pageId];
    if (stroke != null) {
      getActiveLayer(pageIndex).strokes.add(stroke);
      activeStrokes[pageId] = null;
      notifyListeners();
    }
  }

  void moveSelectedStrokes(Offset delta) {
    for (var page in currentNote.pages) {
      for (var layer in page.layers) {
        for (var stroke in layer.strokes) {
          if (stroke.isSelected) {
            stroke.transformOffset += delta;
          }
        }
      }
    }
    notifyListeners();
  }

  void finalizeSelection() {
    for (var page in currentNote.pages) {
      for (var layer in page.layers) {
        for (var stroke in layer.strokes) {
          if (stroke.isSelected) {
             // simplified
          }
        }
      }
    }
  }

  void eraseAt(int pageIndex, Offset point) {
    final layer = getActiveLayer(pageIndex);
    if (eraserType == EraserType.object) {
      layer.strokes.removeWhere((stroke) => stroke.bounds.inflate(5).contains(point));
    } else {
      layer.strokes.removeWhere((stroke) => stroke.points.any((p) => (p.offset - point).distance < eraserWidth / 2));
    }
    notifyListeners();
  }

  void addImage(int pageIndex, Uint8List bytes) {
    currentNote.pages[pageIndex].items.add(ImageItem(
      DateTime.now().toString(),
      100, 100, 300, 300, bytes
    ));
    notifyListeners();
  }

  void addTextItem(int pageIndex, String text) {
    currentNote.pages[pageIndex].items.add(TextItem(
      DateTime.now().toString(),
      150, 150, 200, 50, text
    ));
    notifyListeners();
  }

  void addAudioItem(int pageIndex, int seconds) {
    currentNote.pages[pageIndex].items.add(AudioItem(
      'audio_${DateTime.now().millisecondsSinceEpoch}',
      50, 50, 240, 60, seconds
    ));
    notifyListeners();
  }

  void updateCanvasItemPosition(CanvasItem item, Offset delta) {
    item.x += delta.dx;
    item.y += delta.dy;
    notifyListeners();
  }

  void updateCanvasItemSize(CanvasItem item, Offset delta) {
    if (item.width == 0 || item.height == 0) return;
    double currentRatio = item.width / item.height;
    
    double change = delta.dx;
    
    double newWidth = (item.width + change).clamp(50.0, 1500.0);
    item.width = newWidth;
    item.height = newWidth / currentRatio;
    
    notifyListeners();
  }

  void updateImageCropped(ImageItem item, Uint8List newBytes, double realWidth, double realHeight) {
    saveHistory();
    item.imageBytes = newBytes;
    item.height = item.width * (realHeight / realWidth);
    notifyListeners();
  }
  
  void finishItemMovement() {
    saveHistory();
  }

  void toggleCanvasItemLock(CanvasItem item) {
    item.isLocked = !item.isLocked;
    notifyListeners();
  }

  void duplicateCanvasItem(int pageIndex, CanvasItem item) {
    final newItem = item.copy();
    newItem.x += 20;
    newItem.y += 20;
    currentNote.pages[pageIndex].items.add(newItem);
    notifyListeners();
  }

  void deleteCanvasItem(int pageIndex, CanvasItem item) {
    saveHistory();
    currentNote.pages[pageIndex].items.remove(item);
    notifyListeners();
  }

  void addLayerToAllPages() {
    int newIndex = currentNote.pages[0].layers.length + 1;
    String newId = DateTime.now().toString();
    for (var page in currentNote.pages) {
      page.layers.insert(0, LayerData(id: '${newId}_${page.id}', name: 'Layer $newIndex'));
    }
    activeLayerIndex = 0;
    notifyListeners();
  }
  
  void addPage({int? atIndex}) {
    final newPage = PageData(id: 'page_${DateTime.now().millisecondsSinceEpoch}');
    if (atIndex != null && atIndex <= currentNote.pages.length) {
      currentNote.pages.insert(atIndex, newPage);
    } else {
      currentNote.pages.add(newPage);
    }
    notifyListeners();
  }

  void removePage(int index) {
    if (currentNote.pages.length > 1) {
      currentNote.pages.removeAt(index);
      if (activePageIndex >= currentNote.pages.length) {
        activePageIndex = currentNote.pages.length - 1;
      }
      notifyListeners();
    }
  }

  void reorderPages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final page = currentNote.pages.removeAt(oldIndex);
    currentNote.pages.insert(newIndex, page);
    notifyListeners();
  }
  
  void selectLayer(int index) {
    activeLayerIndex = index;
    notifyListeners();
  }

  void toggleLayerVisibility(int index) {
    for (var page in currentNote.pages) {
      page.layers[index].isVisible = !page.layers[index].isVisible;
    }
    notifyListeners();
  }

  void toggleTape(int pageIndex, Offset point) {
    final page = currentNote.pages[pageIndex];
    for (var layer in page.layers) {
      if (layer.isVisible && !layer.isLocked) {
        for (var stroke in layer.strokes) {
          if (stroke.toolType == ToolType.tape && stroke.bounds.contains(point)) {
            stroke.isTapeHidden = !stroke.isTapeHidden;
            notifyListeners();
            return;
          }
        }
      }
    }
  }

  Future<void> playAudio(String audioId) async {
    if (playingAudioId == audioId) {
      await _audioPlayer.stop();
      playingAudioId = null;
    } else {
      playingAudioId = audioId;
      notifyListeners();
      
      try {
        // Mock placeholder sound to confirm engine works
        await _audioPlayer.play(UrlSource('https://www.soundjay.com/buttons/beep-01a.mp3'));
      } catch (e) {
        debugPrint("Playback error: $e");
        await Future.delayed(const Duration(seconds: 3));
      }
      
      playingAudioId = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
