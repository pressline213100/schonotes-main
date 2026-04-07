import 'note.dart';

abstract class FileSystemNode {
  final String id;
  String title;
  DateTime lastModified;
  DateTime? lastOpened; // Added for Recent
  bool isDeleted; // Added for Trash

  FileSystemNode({
    required this.id,
    required this.title,
    required this.lastModified,
    this.lastOpened,
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson();
  
  factory FileSystemNode.fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'folder') return FolderNode.fromJson(json);
    if (json['type'] == 'note') return NoteNode.fromJson(json);
    throw Exception('Unknown FileSystemNode type: ${json['type']}');
  }
}

class FolderNode extends FileSystemNode {
  final List<FileSystemNode> children;

  FolderNode({
    required super.id,
    required super.title,
    required super.lastModified,
    List<FileSystemNode>? children,
  }) : children = children ?? [];

  @override
  Map<String, dynamic> toJson() => {
    'type': 'folder',
    'id': id,
    'title': title,
    'lastModified': lastModified.toIso8601String(),
    'lastOpened': lastOpened?.toIso8601String(),
    'isDeleted': isDeleted,
    'children': children.map((c) => c.toJson()).toList(),
  };

  factory FolderNode.fromJson(Map<String, dynamic> json) => FolderNode(
    id: json['id'],
    title: json['title'],
    lastModified: DateTime.parse(json['lastModified']),
    children: (json['children'] as List?)?.map((c) => FileSystemNode.fromJson(c)).toList(),
  )..lastOpened = json['lastOpened'] != null ? DateTime.parse(json['lastOpened']) : null
   ..isDeleted = json['isDeleted'] ?? false;
}

class NoteNode extends FileSystemNode {
  final Note note;

  NoteNode({
    required super.id,
    required super.title,
    required super.lastModified,
    required this.note,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'note',
    'id': id,
    'title': title,
    'lastModified': lastModified.toIso8601String(),
    'lastOpened': lastOpened?.toIso8601String(),
    'isDeleted': isDeleted,
    'note': note.toJson(),
  };

  factory NoteNode.fromJson(Map<String, dynamic> json) => NoteNode(
    id: json['id'],
    title: json['title'],
    lastModified: DateTime.parse(json['lastModified']),
    note: Note.fromJson(json['note']),
  )..lastOpened = json['lastOpened'] != null ? DateTime.parse(json['lastOpened']) : null
   ..isDeleted = json['isDeleted'] ?? false;
}
