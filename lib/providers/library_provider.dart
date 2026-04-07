import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_system.dart';
import '../models/note.dart';

enum LibraryViewMode { all, recent, trash }

class LibraryProvider extends ChangeNotifier {
  LibraryViewMode _viewMode = LibraryViewMode.all;
  LibraryViewMode get viewMode => _viewMode;

  String _lastSearchQuery = "";
  String get lastSearchQuery => _lastSearchQuery;

  void setViewMode(LibraryViewMode mode) {
    _viewMode = mode;
    _lastSearchQuery = "";
    _selectedIds.clear();
    notifyListeners();
  }

  void setSearchQuery(String query) {
     _lastSearchQuery = query;
     notifyListeners();
  }

  late FolderNode rootFolder;
  List<FolderNode> breadcrumbs = [];
  Set<String> _selectedIds = {};
  Set<String> get selectedIds => _selectedIds;
  bool get isSelectionMode => _selectedIds.isNotEmpty;

  // Tabs / Opened Notes management
  List<NoteNode> openedNotes = [];
  int activeNoteIndex = -1;

  NoteNode? get activeNote => activeNoteIndex >= 0 ? openedNotes[activeNoteIndex] : null;

  void addTab(NoteNode node) {
    int existingIndex = openedNotes.indexWhere((n) => n.id == node.id);
    if (existingIndex != -1) {
       activeNoteIndex = existingIndex;
    } else {
       openedNotes.add(node);
       activeNoteIndex = openedNotes.length - 1;
    }
    notifyListeners();
  }

  void closeTab(String id) {
    int idx = openedNotes.indexWhere((n) => n.id == id);
    if (idx != -1) {
       openedNotes.removeAt(idx);
       if (openedNotes.isEmpty) {
          activeNoteIndex = -1;
       } else {
          activeNoteIndex = (idx >= openedNotes.length) ? openedNotes.length - 1 : idx;
       }
       notifyListeners();
    }
  }

  void setActiveTab(int index) {
     activeNoteIndex = index;
     notifyListeners();
  }

  void markOpened(String id) {
    _searchAndExecute(rootFolder.children, id, (node) {
       node.lastOpened = DateTime.now();
       node.lastModified = DateTime.now();
    });
    _notifyAndSave();
  }

  void renameNode(String id, String newName) {
    _searchAndExecute(rootFolder.children, id, (node) {
       node.title = newName;
       if (node is NoteNode) node.note.title = newName;
    });
    _notifyAndSave();
  }

  void updateNoteCover(String id, int colorValue) {
    _searchAndExecute(rootFolder.children, id, (node) {
       if (node is NoteNode) node.note.coverColorValue = colorValue;
    });
    _notifyAndSave();
  }

  void _searchAndExecute(List<FileSystemNode> nodes, String id, Function(FileSystemNode) action) {
     for (var node in nodes) {
        if (node.id == id) {
           action(node);
           return;
        }
        if (node is FolderNode) {
           _searchAndExecute(node.children, id, action);
        }
     }
  }

  FolderNode get currentFolder => breadcrumbs.isEmpty ? rootFolder : breadcrumbs.last;

  bool isLoaded = false;

  LibraryProvider() {
    rootFolder = FolderNode(id: 'root', title: 'All Notes', lastModified: DateTime.now());
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('library_data');
    if (data != null) {
      try {
        final json = jsonDecode(data);
        rootFolder = FileSystemNode.fromJson(json) as FolderNode;
      } catch (e) {
        _initMockFileSystem();
      }
    } else {
      _initMockFileSystem();
    }
    isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('library_data', jsonEncode(rootFolder.toJson()));
  }

  void saveLibrary() {
    _saveData();
  }

  void _notifyAndSave() {
    notifyListeners();
    _saveData();
  }

  void _initMockFileSystem() {
    rootFolder = FolderNode(
      id: 'root',
      title: 'All Notes',
      lastModified: DateTime.now(),
      children: [
        FolderNode(
           id: 'folder_1', 
           title: 'Math Notes', 
           lastModified: DateTime.now().subtract(const Duration(days: 1)),
           children: [
              NoteNode(
                 id: 'note_1',
                 title: 'Calculus 101',
                 lastModified: DateTime.now(),
                 note: Note(id: 'note_1', title: 'Calculus 101', lastModified: DateTime.now())
              )
           ]
        ),
        NoteNode(
           id: 'note_2',
           title: 'Meeting Ideas',
           lastModified: DateTime.now().subtract(const Duration(days: 2)),
           note: Note(id: 'note_2', title: 'Meeting Ideas', lastModified: DateTime.now())
        )
      ]
    );
  }

  // --- Navigation ---
  void enterFolder(FolderNode folder) {
    breadcrumbs.add(folder);
    notifyListeners();
  }

  void goBack() {
    if (breadcrumbs.isNotEmpty) {
      breadcrumbs.removeLast();
      notifyListeners();
    }
  }

  void goToRoot() {
    breadcrumbs.clear();
    notifyListeners();
  }
  
  void navigateToBreadcrumb(int index) {
     if (index < 0) {
        breadcrumbs.clear();
     } else {
        breadcrumbs = breadcrumbs.sublist(0, index + 1);
     }
     notifyListeners();
  }

  // --- Creation ---
  void createFolder(String title) {
    currentFolder.children.insert(0, FolderNode(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      lastModified: DateTime.now(),
    ));
    _notifyAndSave();
  }

  void createNotebook(String title, {String template = 'grid'}) {
    final note = Note(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      lastModified: DateTime.now(),
      backgroundTemplate: template,
    );
    currentFolder.children.insert(0, NoteNode(
      id: note.id,
      title: title,
      lastModified: note.lastModified,
      note: note,
    ));
    _notifyAndSave();
  }
  
  void importExternalNote(Note note) {
    currentFolder.children.insert(0, NoteNode(
      id: note.id,
      title: note.title,
      lastModified: note.lastModified,
      note: note,
    ));
    _notifyAndSave();
  }

  void createNewNote(String title, String template) {
     final note = Note(
        id: 'note_${DateTime.now().millisecondsSinceEpoch}',
        title: title, 
        lastModified: DateTime.now(),
        backgroundTemplate: template
     );
     currentFolder.children.insert(0, NoteNode(
        id: note.id,
        title: title,
        lastModified: note.lastModified,
        note: note,
     ));
     _notifyAndSave();
  }

  void createNewFolder(String title) {
     currentFolder.children.insert(0, FolderNode(
        id: 'folder_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        lastModified: DateTime.now(),
        children: []
     ));
     _notifyAndSave();
  }

  void createNewNoteWithImage(String title, Uint8List bytes) {
     final note = Note(
        id: 'note_img_${DateTime.now().millisecondsSinceEpoch}',
        title: title, 
        lastModified: DateTime.now(),
     );
     note.coverColorValue = Colors.purple.value; 
     final node = NoteNode(
        id: note.id,
        title: title,
        lastModified: note.lastModified,
        note: note,
     );
     // Decode image to get original aspect ratio
     ui.decodeImageFromList(bytes, (img) {
       double width = img.width.toDouble();
       double height = img.height.toDouble();
       
       // scale down if too large
       if (width > 400) {
         double ratio = 400 / width;
         width = 400;
         height = height * ratio;
       }
       if (height > 400) {
         double ratio = 400 / height;
         height = 400;
         width = width * ratio;
       }
       
       note.pages[0].items.add(ImageItem(
         'img_init', 50, 50, width, height, bytes
       ));
       currentFolder.children.insert(0, node);
       _notifyAndSave();
     });
  }

  List<NoteNode> getSiblingsOf(String noteId) {
     FolderNode? parent = _findParentOf(rootFolder, noteId);
     if (parent == null) return [];
     return parent.children.whereType<NoteNode>().toList();
  }

  List<FileSystemNode> getPeersOf(String noteId) {
     FolderNode? parent = _findParentOf(rootFolder, noteId);
     if (parent == null) return [];
     return parent.children;
  }

  FolderNode? _findParentOf(FolderNode folder, String id) {
     if (folder.children.any((n) => n.id == id)) return folder;
     for (var child in folder.children) {
       if (child is FolderNode) {
         final p = _findParentOf(child, id);
         if (p != null) return p;
       }
     }
     return null;
  }

  // --- Selection & Actions ---
  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  void deleteSelected() {
    // Soft Delete: Move to Trash
    for (var node in currentFolder.children) {
      if (_selectedIds.contains(node.id)) {
        node.isDeleted = true;
      }
    }
    _selectedIds.clear();
    _notifyAndSave();
  }

  void restoreSelected() {
    // Search recursively in whole tree since they might not be in currentFolder
    void findAndRestore(List<FileSystemNode> nodes) {
      for (var node in nodes) {
        if (_selectedIds.contains(node.id)) node.isDeleted = false;
        if (node is FolderNode) findAndRestore(node.children);
      }
    }
    findAndRestore(rootFolder.children);
    _selectedIds.clear();
    _notifyAndSave();
  }

  List<FileSystemNode> get trashNodes {
    List<FileSystemNode> results = [];
    void search(List<FileSystemNode> nodes) {
      for (var node in nodes) {
        if (node.isDeleted) results.add(node);
        if (node is FolderNode) search(node.children);
      }
    }
    search(rootFolder.children);
    return results..sort((a,b) => b.lastModified.compareTo(a.lastModified));
  }

  List<FileSystemNode> get recentNodes {
    List<FileSystemNode> results = [];
    void search(List<FileSystemNode> nodes) {
      for (var node in nodes) {
        if (!node.isDeleted && node.lastOpened != null) results.add(node);
        if (node is FolderNode) search(node.children);
      }
    }
    search(rootFolder.children);
    return results..sort((a,b) => (b.lastOpened ?? b.lastModified).compareTo(a.lastOpened ?? a.lastModified));
  }

  void emptyTrash() {
     void removeDeleted(List<FileSystemNode> nodes) {
        nodes.removeWhere((n) => n.isDeleted);
        for (var n in nodes) {
          if (n is FolderNode) removeDeleted(n.children);
        }
     }
     removeDeleted(rootFolder.children);
     _notifyAndSave();
  }

  void moveSelectedTo(FolderNode target) {
    if (target == currentFolder) return;
    
    final toMove = currentFolder.children.where((node) => _selectedIds.contains(node.id)).toList();
    currentFolder.children.removeWhere((node) => _selectedIds.contains(node.id));
    target.children.addAll(toMove);
    
    _selectedIds.clear();
    _notifyAndSave();
  }

  List<FolderNode> getAllFolders() {
    List<FolderNode> folders = [];
    void traverse(FolderNode node) {
      folders.add(node);
      for (var child in node.children) {
        if (child is FolderNode) traverse(child);
      }
    }
    traverse(rootFolder);
    return folders;
  }
}
