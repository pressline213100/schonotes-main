import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/canvas_provider.dart';
import '../providers/library_provider.dart';
import '../models/stroke.dart';
import '../models/file_system.dart';

class TopToolbar extends StatelessWidget {
  final CanvasProvider provider;
  const TopToolbar({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (Theme.of(context).appBarTheme.backgroundColor ?? Colors.white).withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Consumer<LibraryProvider>(
                builder: (context, library, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHomeButton(context),
                      _buildPeerShortcuts(context, library),
                      _buildFolderShortcuts(context, library),

                      Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 8)),
                      
                      // Undo / Redo
                      IconButton(
                        icon: Icon(Icons.undo, color: provider.canUndo ? null : Colors.grey.withOpacity(0.4)),
                        onPressed: provider.canUndo ? () => provider.undo() : null,
                        tooltip: 'Undo',
                      ),
                      IconButton(
                        icon: Icon(Icons.redo, color: provider.canRedo ? null : Colors.grey.withOpacity(0.4)),
                        onPressed: provider.canRedo ? () => provider.redo() : null,
                        tooltip: 'Redo',
                      ),

                      Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 8)),

                      // Tools
                      _ToolButton(
                        icon: Icons.mouse,
                        tool: ToolType.select,
                        activeTool: provider.activeTool,
                        onTap: () => provider.setActiveTool(ToolType.select),
                      ),
                      
                      // Touch Drawing Toggle
                      IconButton(
                        tooltip: 'Draw with Finger',
                        icon: Icon(
                          Icons.touch_app, 
                          color: provider.drawWithFinger ? Colors.blue : Colors.grey.withOpacity(0.5)
                        ),
                        onPressed: () => provider.toggleDrawWithFinger(),
                      ),
                      
                      Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 8)),
                      
                      _ToolButton(
                        icon: Icons.edit,
                        tool: ToolType.pen,
                        activeTool: provider.activeTool,
                        onTap: () {
                           if (provider.activeTool == ToolType.pen) {
                             _showPenSettings(context, provider);
                           } else {
                             provider.setActiveTool(ToolType.pen);
                           }
                        },
                      ),
                      _ToolButton(
                        icon: Icons.brush,
                        tool: ToolType.highlighter,
                        activeTool: provider.activeTool,
                        onTap: () {
                           if (provider.activeTool == ToolType.highlighter) {
                             _showHighlighterSettings(context, provider);
                           } else {
                             provider.setActiveTool(ToolType.highlighter);
                           }
                        },
                      ),
                      _ToolButton(
                         icon: Icons.auto_fix_normal,
                         tool: ToolType.eraser,
                         activeTool: provider.activeTool,
                         onTap: () {
                            if (provider.activeTool == ToolType.eraser) {
                              _showEraserSettings(context, provider);
                            } else {
                              provider.setActiveTool(ToolType.eraser);
                            }
                         },
                      ),
                      
                      _ToolButton(
                        icon: Icons.movie_filter_outlined,
                        tool: ToolType.tape,
                        activeTool: provider.activeTool,
                        onTap: () => provider.setActiveTool(ToolType.tape),
                      ),
                      _ToolButton(
                        icon: Icons.select_all,
                        tool: ToolType.lasso,
                        activeTool: provider.activeTool,
                        onTap: () => provider.setActiveTool(ToolType.lasso),
                      ),
                      
                      // Recording Integrated!
                      _ToolButton(
                        icon: provider.isRecording ? Icons.stop_circle : Icons.mic,
                        tool: ToolType.select, // dummy
                        activeTool: provider.isRecording ? ToolType.select : ToolType.pen, // dummy
                        onTap: () => provider.toggleRecording(),
                        activeColor: provider.isRecording ? Colors.redAccent : null,
                      ),

                      _ToolButton(
                        icon: Icons.text_fields,
                        tool: ToolType.text,
                        activeTool: provider.activeTool,
                        onTap: () => provider.setActiveTool(ToolType.text),
                      ),
                      _ToolButton(
                        icon: Icons.image,
                        tool: ToolType.image,
                        activeTool: provider.activeTool,
                        onTap: () {
                           provider.setActiveTool(ToolType.image);
                           _pickImage(context, provider);
                        },
                      ),
                      
                      Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 8)),
                      _ToolButton(
                        icon: Icons.horizontal_rule,
                        tool: ToolType.straightLine,
                        activeTool: provider.activeTool,
                        onTap: () => provider.setActiveTool(ToolType.straightLine),
                      ),
                      _ToolButton(
                        icon: Icons.circle_outlined,
                        tool: ToolType.circle,
                        activeTool: provider.activeTool,
                        onTap: () => provider.setActiveTool(ToolType.circle),
                      ),

                      Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 8)),
                      ...List.generate(3, (index) => _ColorSlotButton(index: index, provider: provider)),
                      
                      Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 8)),
                      
                      ...List.generate(3, (index) => _WidthSlotButton(index: index, provider: provider)),
                      
                      Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 8)),

                      IconButton(
                        icon: Icon(Icons.description_outlined, color: provider.currentNote.paperColor != 'white' ? Colors.blue : null),
                        tooltip: 'Paper Settings',
                        onPressed: () => _showPaperSettings(context, provider),
                      ),
                      IconButton(
                        tooltip: 'Layers',
                        icon: Icon(Icons.layers, color: provider.isLayerPanelVisible ? Colors.blue : null),
                        onPressed: () => provider.toggleLayerPanel(),
                      ),
                      IconButton(
                        tooltip: 'Pages',
                        icon: const Icon(Icons.auto_stories_outlined),
                        onPressed: () => provider.showPageManager(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
     return IconButton(
       icon: const Icon(Icons.home_outlined),
       onPressed: () => Navigator.pop(context),
       tooltip: 'Back to Home',
     );
  }

  Widget _buildPeerShortcuts(BuildContext context, LibraryProvider library) {
     final peers = library.getPeersOf(provider.currentNote.id);
     final notes = peers.whereType<NoteNode>().toList();
     
     return Row(
       mainAxisSize: MainAxisSize.min,
       children: notes.map((note) {
         bool isCurrent = note.id == provider.currentNote.id;
         return Padding(
           padding: const EdgeInsets.symmetric(horizontal: 4),
           child: InkWell(
             onTap: () {
               if (isCurrent) return;
               provider.loadNote(note.note);
               library.addTab(note);
             },
             borderRadius: BorderRadius.circular(12),
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
               decoration: BoxDecoration(
                 color: isCurrent ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: isCurrent ? Colors.blue.withOpacity(0.3) : Colors.transparent),
               ),
               child: Row(
                 children: [
                   Icon(Icons.note_alt_outlined, size: 16, color: isCurrent ? Colors.blue : Colors.grey),
                   const SizedBox(width: 4),
                   Text(
                     note.title,
                     style: TextStyle(
                       fontSize: 12, 
                       fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                       color: isCurrent ? Colors.blue : Colors.grey.shade700
                     ),
                   ),
                 ],
               ),
             ),
           ),
         );
       }).toList(),
     );
  }

  Widget _buildFolderShortcuts(BuildContext context, LibraryProvider library) {
     final allFolders = library.getAllFolders();
     final peerFolders = library.getPeersOf(provider.currentNote.id).whereType<FolderNode>().toList();
     
     return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...peerFolders.take(3).map((folder) => IconButton(
            icon: const Icon(Icons.folder_open_outlined, size: 20, color: Colors.orangeAccent),
            onPressed: () {},
            tooltip: folder.title,
          )),
          PopupMenuButton<FolderNode>(
            icon: const Icon(Icons.folder_copy_outlined, size: 20, color: Colors.grey),
            tooltip: 'All Folders',
            onSelected: (f) {},
            itemBuilder: (ctx) => allFolders.map((f) => PopupMenuItem(
              value: f,
              child: Row(
                children: [
                  const Icon(Icons.folder, size: 16, color: Colors.orangeAccent),
                  const SizedBox(width: 8),
                  Text(f.title),
                ],
              ),
            )).toList(),
          ),
        ],
     );
  }

  Future<void> _pickImage(BuildContext context, CanvasProvider provider) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.single.bytes != null) {
       provider.addImage(0, result.files.single.bytes!);
       provider.setActiveTool(ToolType.pen); 
    }
  }
  
// unused methods removed

  void _showPaperSettings(BuildContext context, CanvasProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Paper Color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _PaperColorTip(color: Colors.white, name: 'white', current: provider.currentNote.paperColor, onSelect: (n) { provider.setPaperColor(n); setModalState(() {}); }),
                      _PaperColorTip(color: Colors.grey.shade300, name: 'gray', current: provider.currentNote.paperColor, onSelect: (n) { provider.setPaperColor(n); setModalState(() {}); }),
                      _PaperColorTip(color: const Color(0xFFF5F5DC), name: 'beige', current: provider.currentNote.paperColor, onSelect: (n) { provider.setPaperColor(n); setModalState(() {}); }),
                      _PaperColorTip(color: const Color(0xFFC4A484), name: 'kraft', current: provider.currentNote.paperColor, onSelect: (n) { provider.setPaperColor(n); setModalState(() {}); }),
                      _PaperColorTip(color: Colors.black, name: 'black', current: provider.currentNote.paperColor, onSelect: (n) { provider.setPaperColor(n); setModalState(() {}); }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Template', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _TemplateButton(label: 'Blank', value: 'blank', current: provider.currentNote.backgroundTemplate, onSelect: (v) { provider.setBackgroundTemplate(v); setModalState(() {}); }),
                      _TemplateButton(label: 'Grid', value: 'grid', current: provider.currentNote.backgroundTemplate, onSelect: (v) { provider.setBackgroundTemplate(v); setModalState(() {}); }),
                      _TemplateButton(label: 'Lines', value: 'lines', current: provider.currentNote.backgroundTemplate, onSelect: (v) { provider.setBackgroundTemplate(v); setModalState(() {}); }),
                    ],
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }
  void _showPenSettings(BuildContext context, CanvasProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('Pen Style', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 16),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceAround,
                     children: [
                       ChoiceChip(
                         label: const Text('Ballpoint Pen'),
                         selected: provider.penThinning == 0.0,
                         onSelected: (val) {
                           if (val) provider.penThinning = 0.0;
                           setModalState(() {});
                         },
                       ),
                       ChoiceChip(
                         label: const Text('Fountain Pen'),
                         selected: provider.penThinning > 0.0 && provider.penThinning <= 0.6,
                         onSelected: (val) {
                           if (val) provider.penThinning = 0.6;
                           setModalState(() {});
                         },
                       ),
                       ChoiceChip(
                         label: const Text('Brush Pen'),
                         selected: provider.penThinning > 0.6,
                         onSelected: (val) {
                           if (val) provider.penThinning = 0.95;
                           setModalState(() {});
                         },
                       ),
                     ],
                   ),
                   const SizedBox(height: 24),
                   const Text('Pen Thickness', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   Slider(
                     value: provider.activeWidth,
                     min: 1.0,
                     max: 20.0,
                     label: provider.activeWidth.round().toString(),
                     onChanged: (double value) {
                       setModalState(() {
                         provider.setActiveWidth(value);
                       });
                     },
                   ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _showHighlighterSettings(BuildContext context, CanvasProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('Highlighter Thickness', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 16),
                   Slider(
                     value: provider.activeWidth,
                     min: 5.0,
                     max: 40.0,
                     label: provider.activeWidth.round().toString(),
                     onChanged: (double value) {
                       setModalState(() {
                         provider.setActiveWidth(value);
                       });
                     },
                   ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _showEraserSettings(BuildContext context, CanvasProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('Eraser Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 16),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceAround,
                     children: [
                       ChoiceChip(
                         label: const Text('Object Eraser'),
                         selected: provider.eraserType == EraserType.object,
                         onSelected: (val) {
                           if (val) provider.eraserType = EraserType.object;
                           setModalState(() {});
                         },
                       ),
                       ChoiceChip(
                         label: const Text('Pixel Eraser'),
                         selected: provider.eraserType == EraserType.pixel,
                         onSelected: (val) {
                           if (val) provider.eraserType = EraserType.pixel;
                           setModalState(() {});
                         },
                       ),
                     ],
                   ),
                   const SizedBox(height: 24),
                   const Text('Eraser Size', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   Slider(
                     value: provider.eraserWidth,
                     min: 10.0,
                     max: 100.0,
                     label: provider.eraserWidth.round().toString(),
                     onChanged: (double value) {
                       setModalState(() {
                         provider.setActiveWidth(value);
                       });
                     },
                   ),
                ],
              ),
            );
          }
        );
      }
    );
  }
}

class _ColorSlotButton extends StatelessWidget {
  final int index;
  final CanvasProvider provider;
  const _ColorSlotButton({required this.index, required this.provider});

  @override
  Widget build(BuildContext context) {
    bool isSelected = index == provider.activeColorSlot;
    Color color = provider.presetColors[index];

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          _showColorPickerForSlot(context, provider, index);
        } else {
          provider.setActiveColorSlot(index);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: isSelected ? 30 : 24,
        height: isSelected ? 30 : 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.grey.shade400,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }

  void _showColorPickerForSlot(BuildContext context, CanvasProvider provider, int index) {
    Color pickerColor = provider.presetColors[index];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (c) => pickerColor = c,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Select'),
              onPressed: () {
                provider.updateColorSlot(index, pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class _WidthSlotButton extends StatelessWidget {
  final int index;
  final CanvasProvider provider;
  const _WidthSlotButton({required this.index, required this.provider});

  @override
  Widget build(BuildContext context) {
    bool isSelected = index == provider.activeWidthSlot;
    double width = provider.presetWidths[index];
    
    // Normalize rendering radius
    double renderRadius = (width.clamp(1.0, 10.0)) + 2.0;

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          _showWidthSliderForSlot(context, provider, index);
        } else {
          provider.setActiveWidthSlot(index);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.blue.withOpacity(0.15) : Colors.transparent,
        ),
        child: Container(
           width: renderRadius,
           height: renderRadius,
           decoration: const BoxDecoration(
             color: Colors.black87,
             shape: BoxShape.circle,
           ),
        ),
      ),
    );
  }

  void _showWidthSliderForSlot(BuildContext context, CanvasProvider provider, int index) {
    double currentWidth = provider.presetWidths[index];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: 150,
              child: Column(
                children: [
                   Text('Stroke Width: ${currentWidth.toStringAsFixed(1)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   Slider(
                     value: currentWidth,
                     min: 1.0,
                     max: 20.0,
                     label: currentWidth.round().toString(),
                     onChanged: (double value) {
                       setModalState(() {
                         currentWidth = value;
                         provider.updateWidthSlot(index, value);
                       });
                     },
                   ),
                ],
              ),
            );
          }
        );
      }
    );
  }
}

class _PaperColorTip extends StatelessWidget {
  final Color color;
  final String name;
  final String current;
  final Function(String) onSelect;
  const _PaperColorTip({required this.color, required this.name, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    bool isSelected = name == current;
    return GestureDetector(
      onTap: () => onSelect(name),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade400, width: isSelected ? 3 : 1),
        ),
      ),
    );
  }
}

class _TemplateButton extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final Function(String) onSelect;
  const _TemplateButton({required this.label, required this.value, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    bool isSelected = value == current;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (s) => onSelect(value),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final ToolType tool;
  final ToolType activeTool;
  final VoidCallback onTap;
  final Color? activeColor;

  const _ToolButton({
    required this.icon,
    required this.tool,
    required this.activeTool,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = tool == activeTool;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: activeColor ?? (isSelected ? Colors.blue : Theme.of(context).iconTheme.color)),
      ),
    );
  }
}

// unused classes removed
