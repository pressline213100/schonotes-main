import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/file_system.dart';
import '../providers/library_provider.dart';
import '../providers/cloud_sync_provider.dart';
import 'canvas_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        bool isSelection = library.isSelectionMode;
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          extendBodyBehindAppBar: true,
          drawer: isSelection ? null : _buildDrawer(context, library),
          appBar: AppBar(
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5)),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: Theme.of(context).iconTheme,
            leading: isSelection 
              ? IconButton(icon: const Icon(Icons.close), onPressed: () => library.clearSelection()) 
              : null,
            title: isSelection 
              ? Text('${library.selectedIds.length} Selected') 
              : _buildSearchField(library),
            actions: isSelection 
              ? _buildSelectionActions(context, library)
              : [
                  Consumer<CloudSyncProvider>(
                    builder: (context, syncProvider, child) {
                      return Row(
                        children: [
                          IconButton(
                            icon: syncProvider.isSyncing 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                                : const Icon(Icons.save_alt, color: Colors.blueAccent),
                            tooltip: 'Backup Data',
                            onPressed: syncProvider.isSyncing ? null : () => _showBackupDialog(context, syncProvider, library),
                          ),
                          const SizedBox(width: 16),
                        ],
                      );
                    }
                  ),
                ],
          ),
          body: _buildBody(context, library),
          floatingActionButton: (isSelection || library.viewMode == LibraryViewMode.trash) ? null : _buildMultiActionFAB(context, library),
        );
      }
    );
  }

  Widget _buildSearchField(LibraryProvider library) {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: TextField(
        onChanged: (val) => library.setSearchQuery(val),
        decoration: const InputDecoration(
          hintText: 'Search Notes...',
          prefixIcon: Icon(Icons.search, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LibraryProvider library) {
    List<FileSystemNode> items;
    if (library.viewMode == LibraryViewMode.recent) {
       items = library.recentNodes;
    } else if (library.viewMode == LibraryViewMode.trash) {
       items = library.trashNodes;
    } else {
       items = library.currentFolder.children.where((n) => !n.isDeleted).toList();
    }

    if (library.lastSearchQuery.isNotEmpty) {
       items = items.where((n) => n.title.toLowerCase().contains(library.lastSearchQuery.toLowerCase())).toList();
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              library.viewMode == LibraryViewMode.trash ? Icons.delete_outline : Icons.search_off, 
              size: 60, 
              color: Colors.grey.withOpacity(0.3)
            ),
            const SizedBox(height: 16),
            Text(
              library.viewMode == LibraryViewMode.trash ? 'Trash is empty' : 'No matches found',
              style: const TextStyle(color: Colors.black45, fontSize: 16)
            ),
          ],
        )
      );
    }
    return Column(
      children: [
        if (library.viewMode == LibraryViewMode.all && library.breadcrumbs.isNotEmpty)
          _buildBreadcrumbsRow(context, library),
        Expanded(child: _buildGridView(context, library, items)),
      ],
    );
  }

  Widget _buildBreadcrumbsRow(BuildContext context, LibraryProvider library) {
     return Container(
       height: 36,
       padding: const EdgeInsets.symmetric(horizontal: 16),
       child: ListView.separated(
         scrollDirection: Axis.horizontal,
         itemCount: library.breadcrumbs.length + 1,
         separatorBuilder: (_, __) => const Icon(Icons.chevron_right, size: 14),
         itemBuilder: (context, i) {
            String title = i == 0 ? "Root" : library.breadcrumbs[i-1].title;
            return TextButton(
              onPressed: () => library.navigateToBreadcrumb(i - 1),
              child: Text(title, style: const TextStyle(fontSize: 12)),
            );
         },
       ),
     );
  }

  Widget _buildGridView(BuildContext context, LibraryProvider library, List<FileSystemNode> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth > 900) {
          crossAxisCount = 8;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 6;
        }
        
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16, 
            mainAxisSpacing: 20, 
            childAspectRatio: 0.68
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final node = items[index];
            bool isSelected = library.selectedIds.contains(node.id);
            
            return HoverScaleContainer(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (library.isSelectionMode) {
                    library.toggleSelection(node.id);
                  } else if (node.isDeleted) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Restore to view this note")));
                  } else if (node is NoteNode) {
                    library.markOpened(node.id);
                    library.addTab(node);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CanvasScreen()));
                  } else if (node is FolderNode) {
                    library.enterFolder(node);
                  }
                },
                onLongPress: () => library.toggleSelection(node.id),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _NotebookCoverWidget(
                        title: node.title,
                        color: (node is NoteNode) ? Color(node.note.coverColorValue) : Colors.grey.shade400,
                        isSelected: library.isSelectionMode ? isSelected : false,
                        isFolder: node is FolderNode,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    node.title, 
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                ],
              ),
              ),
            );
          },
        );
      }
    );
  }

  List<Widget> _buildSelectionActions(BuildContext context, LibraryProvider library) {
    if (library.viewMode == LibraryViewMode.trash) {
       return [
          IconButton(icon: const Icon(Icons.restore_from_trash), onPressed: () => library.restoreSelected()),
          IconButton(icon: const Icon(Icons.delete_forever), onPressed: () => library.deleteSelected()),
       ];
    }
    return [
      if (library.selectedIds.length == 1) ...[
          IconButton(
            icon: const Icon(Icons.edit_note), 
            onPressed: () => _showRenameDialog(context, library, library.selectedIds.first)
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined), 
            onPressed: () => _showColorPicker(context, library, library.selectedIds.first)
          ),
      ],
      IconButton(icon: const Icon(Icons.drive_file_move_outlined), onPressed: () {}),
      IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => library.deleteSelected()),
    ];
  }

  void _showRenameDialog(BuildContext context, LibraryProvider library, String id) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Item'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'New name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              library.renameNode(id, controller.text);
              library.clearSelection();
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      )
    );
  }

  void _showColorPicker(BuildContext context, LibraryProvider library, String id) {
     final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.brown, Colors.teal, Colors.black];
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         title: const Text('Change Cover Color'),
         content: Wrap(
           spacing: 12, runSpacing: 12,
           children: colors.map((c) => InkWell(
             onTap: () {
               library.updateNoteCover(id, c.value);
               library.clearSelection();
               Navigator.pop(ctx);
             },
             child: CircleAvatar(backgroundColor: c, radius: 20),
           )).toList(),
         ),
       )
     );
  }

  Widget _buildDrawer(BuildContext context, LibraryProvider library) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Note Station', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Professional Hub', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.library_books),
            title: const Text('My Library'),
            selected: library.viewMode == LibraryViewMode.all,
            onTap: () { library.setViewMode(LibraryViewMode.all); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Recently Opened'),
            selected: library.viewMode == LibraryViewMode.recent,
            onTap: () { library.setViewMode(LibraryViewMode.recent); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Recycle Bin'),
            selected: library.viewMode == LibraryViewMode.trash,
            onTap: () { library.setViewMode(LibraryViewMode.trash); Navigator.pop(context); },
          ),
        ],
      ),
    );
  }

  Widget _buildMultiActionFAB(BuildContext context, LibraryProvider library) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: FloatingActionButton(
          onPressed: () => _showCreateMenu(context, library),
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).bottomSheetTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.5), borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.note_add, color: Colors.blueAccent),
              ),
              title: const Text('New Note', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Create a blank canvas or template'),
              onTap: () {
                Navigator.pop(ctx);
                _showNewNoteDialog(context, library);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.create_new_folder, color: Colors.orangeAccent),
              ),
              title: const Text('New Folder', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Organize your documents'),
              onTap: () {
                Navigator.pop(ctx);
                _showNewFolderDialog(context, library);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.image, color: Colors.purpleAccent),
              ),
              title: const Text('Import Image', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Create a note from a photo'),
              onTap: () {
                 Navigator.pop(ctx);
                 _importImage(context, library);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _importImage(BuildContext context, LibraryProvider library) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.single.bytes != null) {
       library.createNewNoteWithImage(result.files.single.name, result.files.single.bytes!);
    }
  }

  void _showBackupDialog(BuildContext context, CloudSyncProvider syncProvider, LibraryProvider library) {
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         title: const Text('Data Backup'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const Icon(Icons.folder_zip, size: 50, color: Colors.blueGrey),
             const SizedBox(height: 12),
             const Text('Export your library to a JSON file or restore from an existing backup.', textAlign: TextAlign.center),
             const SizedBox(height: 16),
             if (syncProvider.lastSyncTime != null)
               Text(
                 'Last Action: ${syncProvider.lastSyncTime!.month}/${syncProvider.lastSyncTime!.day} ${syncProvider.lastSyncTime!.hour}:${syncProvider.lastSyncTime!.minute.toString().padLeft(2, '0')}',
                 style: const TextStyle(fontSize: 12, color: Colors.grey),
               ),
           ],
         ),
         actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Export'),
              onPressed: () { 
                Navigator.pop(ctx);
                final jsonStr = jsonEncode(library.rootFolder.toJson());
                syncProvider.exportBackup(jsonStr);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Import'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async { 
                Navigator.pop(ctx);
                final jsonStr = await syncProvider.importBackup();
                if (jsonStr != null) {
                   try {
                     final map = jsonDecode(jsonStr);
                     library.rootFolder = FileSystemNode.fromJson(map) as FolderNode;
                     library.saveLibrary();
                     library.goToRoot();
                   } catch (e) {
                     if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to parse backup: $e')));
                     }
                   }
                }
              },
            ),
         ],
       )
     );
  }

  void _showNewNoteDialog(BuildContext context, LibraryProvider library) {
    final controller = TextEditingController();
    String selectedTemplate = 'blank';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Note Title')),
              const SizedBox(height: 20),
              const Text('Select Template', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                   ChoiceChip(
                     label: const Text('Blank'), 
                     selected: selectedTemplate == 'blank', 
                     onSelected: (_) => setDialogState(() => selectedTemplate = 'blank')
                   ),
                   ChoiceChip(
                     label: const Text('Grid'), 
                     selected: selectedTemplate == 'grid', 
                     onSelected: (_) => setDialogState(() => selectedTemplate = 'grid')
                   ),
                   ChoiceChip(
                     label: const Text('Lines'), 
                     selected: selectedTemplate == 'lines', 
                     onSelected: (_) => setDialogState(() => selectedTemplate = 'lines')
                   ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                library.createNewNote(controller.text.isEmpty ? "Untitled Note" : controller.text, selectedTemplate);
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewFolderDialog(BuildContext context, LibraryProvider library) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Folder Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              library.createNewFolder(controller.text.isEmpty ? "Untitled Folder" : controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      )
    );
  }
}

class _NotebookCoverWidget extends StatelessWidget {
  final String title;
  final Color color;
  final bool isSelected;
  final bool isFolder;
  const _NotebookCoverWidget({required this.title, required this.color, required this.isSelected, required this.isFolder});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isFolder ? Colors.orangeAccent.shade200 : color.withOpacity(0.7),
            isFolder ? Colors.deepOrangeAccent : color,
          ],
        ),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16), topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), offset: const Offset(4, 6), blurRadius: 10),
          BoxShadow(color: Colors.black.withOpacity(0.1), offset: const Offset(0, 2), blurRadius: 4),
        ],
        border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3) : null,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0, top: 0, bottom: 0, width: 14,
            child: Container(decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.0)],
                begin: Alignment.centerLeft, end: Alignment.centerRight
              )
            )),
          ),
          Center(
            child: isFolder 
              ? const Icon(Icons.folder_shared, color: Colors.white, size: 36)
              : Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                  child: Text(
                    title.isNotEmpty ? title.substring(0, 1).toUpperCase() : "?", 
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20)
                  ),
                ),
          ),
          if (isSelected) Positioned(top: 8, right: 8, child: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 22)),
        ],
      ),
    );
  }
}

class HoverScaleContainer extends StatefulWidget {
  final Widget child;
  const HoverScaleContainer({required this.child, super.key});
  @override
  State<HoverScaleContainer> createState() => _HoverScaleContainerState();
}

class _HoverScaleContainerState extends State<HoverScaleContainer> {
  bool isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedScale(
        scale: isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transformAlignment: FractionalOffset.center,
          transform: Matrix4.translationValues(0, isHovered ? -4 : 0, 0),
          child: widget.child,
        ),
      ),
    );
  }
}
