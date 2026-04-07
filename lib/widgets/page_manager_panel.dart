import 'dart:ui';
import 'package:flutter/material.dart';
import '../providers/canvas_provider.dart';

class PageManagerPanel extends StatelessWidget {
  final CanvasProvider provider;
  const PageManagerPanel({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(top: 80, right: 16, bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withOpacity(0.9), // Dark background
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 5))],
            ),
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildPageList()),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Page Manager', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.white70),
            onPressed: () => provider.hidePageManager(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: provider.currentNote.pages.length,
      onReorder: (oldIndex, newIndex) => provider.reorderPages(oldIndex, newIndex),
      itemBuilder: (context, index) {
        final page = provider.currentNote.pages[index];
        bool isActive = index == provider.activePageIndex;
        
        return Container(
          key: ValueKey(page.id),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: InkWell(
            onTap: () => provider.activePageIndex = index,
            child: Column(
              children: [
                Stack(
                  children: [
                    // Mock Thumbnail (Dark Version)
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D), // Dark thumbnail background
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? Colors.blueAccent : Colors.white12,
                          width: isActive ? 3 : 1
                        ),
                        boxShadow: isActive ? [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 12)] : null,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}', 
                          style: TextStyle(
                            color: isActive ? Colors.blueAccent.withOpacity(0.5) : Colors.white12, 
                            fontSize: 50, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                    ),
                    Positioned(
                       top: 8, right: 8,
                       child: Column(
                         children: [
                           ReorderableDragStartListener(
                             index: index,
                             child: Container(
                               padding: const EdgeInsets.all(4),
                               decoration: BoxDecoration(
                                 color: Colors.black26,
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               child: const Icon(Icons.drag_handle, color: Colors.white70, size: 24),
                             ),
                           ),
                           const SizedBox(height: 12),
                           IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                              onPressed: () => provider.removePage(index),
                              style: IconButton.styleFrom(backgroundColor: Colors.black26),
                           ),
                         ],
                       ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Page ${index + 1}', 
                  style: TextStyle(
                    fontSize: 13, 
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? Colors.blueAccent : Colors.white70
                  )
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
     return Padding(
       padding: const EdgeInsets.all(16),
       child: ElevatedButton.icon(
          onPressed: () => provider.addPage(),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add New Page', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
             backgroundColor: Colors.blueAccent,
             minimumSize: const Size(double.infinity, 50),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
             elevation: 0,
          ),
       ),
     );
  }
}
