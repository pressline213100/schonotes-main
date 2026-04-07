import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../models/file_system.dart'; // Import NoteNode

class TopTabSwitcher extends StatelessWidget {
  const TopTabSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final tabs = library.openedNotes;
    
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)), // Fix BorderSide
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final node = tabs[index];
                final isActive = library.activeNoteIndex == index;
                
                return GestureDetector(
                  onTap: () => library.setActiveTab(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.blueAccent.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isActive ? Border.all(color: Colors.blueAccent.withOpacity(0.4)) : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.description_outlined, size: 14, color: isActive ? Colors.blueAccent : Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          node.title,
                          style: TextStyle(
                            color: isActive ? Colors.blueAccent : Colors.black87,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () { // Fix parameter
                             library.closeTab(node.id);
                          },
                          child: Icon(Icons.close, size: 14, color: isActive ? Colors.blueAccent : Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Quick Add Tab Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent, size: 22),
              onPressed: () => _showQuickPicker(context, library),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickPicker(BuildContext context, LibraryProvider library) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final recents = library.recentNodes;
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Quick Switch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (recents.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('No recently opened notes', style: TextStyle(color: Colors.grey))),
              ...recents.whereType<NoteNode>().map((n) => ListTile(
                leading: const Icon(Icons.history, color: Colors.blueAccent),
                title: Text(n.title),
                onTap: () {
                  library.addTab(n);
                  Navigator.pop(ctx);
                },
              )).toList(),
            ],
          ),
        );
      }
    );
  }
}
