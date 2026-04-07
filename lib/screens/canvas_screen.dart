import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/canvas_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/drawing_board.dart';
import '../widgets/top_toolbar.dart';
import '../widgets/layer_panel.dart';
import '../widgets/knowledge_panel.dart';
import '../widgets/focus_timer.dart';
import '../widgets/top_tab_switcher.dart';
import 'package:noteful_app/widgets/page_manager_panel.dart';
// import '../widgets/voice_recorder_widget.dart'; // Removed legacy recorder

class CanvasScreen extends StatefulWidget {
  const CanvasScreen({super.key});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  // Floating panel positions
  Offset _posKnowledge = const Offset(20, 150);
  Offset _posTimer = const Offset(300, 60);
  // Offset _posRecorder = const Offset(500, 20); // Removed legacy
  bool _isKnowledgeCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        final activeNode = library.activeNote;
        if (activeNode == null) {
          Future.microtask(() => Navigator.pop(context));
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return ChangeNotifierProvider(
          key: ValueKey(activeNode.id),
          create: (_) => CanvasProvider(currentNote: activeNode.note),
          child: Consumer<CanvasProvider>(
            builder: (context, provider, child) {
              return Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: SafeArea(
                  child: Stack(
                    children: [
                      // Draw Canvas
                      Positioned.fill(
                        top: 45,
                        child: DrawingBoard(provider: provider),
                      ),
                      
                      // 1. Tab Bar (Fixed)
                      const Positioned(top: 0, left: 0, right: 0, child: TopTabSwitcher()),

                      // 2. Toolbar (Fixed/Floating below tabs)
                      if (provider.isToolbarVisible)
                        Positioned(
                          top: 50, left: 0, right: 0,
                          child: Center(child: TopToolbar(provider: provider)),
                        ),

                      // 3. Draggable Knowledge Panel
                      Positioned(
                        left: _posKnowledge.dx,
                        top: _posKnowledge.dy,
                        child: _DraggableWrapper(
                          onDrag: (delta) => setState(() => _posKnowledge += delta),
                          child: KnowledgePanel(
                            isCollapsed: _isKnowledgeCollapsed,
                            onToggleCollapse: () => setState(() => _isKnowledgeCollapsed = !_isKnowledgeCollapsed),
                            onInsertInfo: (info) => provider.addTextItem(provider.activePageIndex, info),
                          ),
                        ),
                      ),

                      // 4. Draggable Timer
                      Positioned(
                        left: _posTimer.dx,
                        top: _posTimer.dy,
                        child: _DraggableWrapper(
                          onDrag: (delta) => setState(() => _posTimer += delta),
                          child: const FocusTimer(),
                        ),
                      ),

                      // Legacy Recorder removed - integration moved to TopToolbar

                      // 6. Right Side Panels (Layer / Page Manager)
                      if (provider.isLayerPanelVisible)
                        Positioned(
                          top: 80, right: 10, bottom: 20,
                          child: LayerPanel(provider: provider),
                        ),
                        
                      if (provider.isPageManagerVisible)
                        Positioned(
                          top: 0, right: 0, bottom: 0,
                          child: PageManagerPanel(provider: provider),
                        ),

                      // 7. Controls & Status
                      _buildBottomBar(context, provider),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, CanvasProvider provider) {
    return Positioned(
      bottom: 20, left: 20, right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: FloatingActionButton(
                mini: true,
                heroTag: 'toggle_toolbar',
                backgroundColor: Theme.of(context).cardColor.withOpacity(0.6),
                elevation: 0,
                onPressed: () => provider.toggleToolbar(),
                child: Icon(provider.isToolbarVisible ? Icons.visibility_off : Icons.visibility, color: Theme.of(context).iconTheme.color),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  'Page ${provider.activePageIndex + 1} / ${provider.currentNote.pages.length}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraggableWrapper extends StatelessWidget {
  final Widget child;
  final Function(Offset) onDrag;
  const _DraggableWrapper({required this.child, required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => onDrag(details.delta),
      child: child,
    );
  }
}
