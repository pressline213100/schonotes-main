import 'dart:convert';
import 'dart:typed_data';
import 'layer.dart';
import 'stroke.dart';

class Note {
  String id;
  String title;
  DateTime lastModified;
  String? coverUrl;
  int coverColorValue; 
  String backgroundTemplate; 
  String paperColor; 
  List<PageData> pages;
  
  Note({
    required this.id,
    required this.title,
    required this.lastModified,
    this.coverUrl,
    this.coverColorValue = 0xFF2196F3, 
    this.backgroundTemplate = 'grid',
    this.paperColor = 'white',
    List<PageData>? pages,
  }) : pages = pages ?? [
    PageData(id: 'page_1'), 
    PageData(id: 'page_2'),
    PageData(id: 'page_3') 
  ];

  Note copy() {
    return Note(
      id: id,
      title: title,
      lastModified: lastModified,
      coverUrl: coverUrl,
      coverColorValue: coverColorValue,
      backgroundTemplate: backgroundTemplate,
      paperColor: paperColor,
      pages: pages.map((p) => p.copy()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'lastModified': lastModified.toIso8601String(),
    'coverUrl': coverUrl,
    'coverColorValue': coverColorValue,
    'backgroundTemplate': backgroundTemplate,
    'paperColor': paperColor,
    'pages': pages.map((p) => p.toJson()).toList(),
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    title: json['title'],
    lastModified: DateTime.parse(json['lastModified']),
    coverUrl: json['coverUrl'],
    coverColorValue: json['coverColorValue'] ?? 0xFF2196F3,
    backgroundTemplate: json['backgroundTemplate'] ?? 'grid',
    paperColor: json['paperColor'] ?? 'white',
    pages: (json['pages'] as List?)?.map((p) => PageData.fromJson(p)).toList(),
  );
}

class PageData {
  String id;
  List<LayerData> layers;
  Uint8List? pdfBytes; 
  List<CanvasItem> items; 
  
  PageData({
    required this.id,
    List<LayerData>? layers,
    this.pdfBytes,
    List<CanvasItem>? items,
  }) : 
    layers = layers ?? [
      LayerData(id: 'layer_1', name: 'Layer 1'),
      LayerData(id: 'layer_2', name: 'Background Layer')
    ],
    items = items ?? [];

  PageData copy() {
    return PageData(
      id: id,
      pdfBytes: pdfBytes,
      layers: layers.map((l) => l.copy()).toList(),
      items: items.map((i) => i.copy()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'layers': layers.map((l) => l.toJson()).toList(),
    'pdfBytes': pdfBytes != null ? base64Encode(pdfBytes!) : null,
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory PageData.fromJson(Map<String, dynamic> json) => PageData(
    id: json['id'],
    layers: (json['layers'] as List?)?.map((l) => LayerData.fromJson(l)).toList(),
    pdfBytes: json['pdfBytes'] != null ? base64Decode(json['pdfBytes']) : null,
    items: (json['items'] as List?)?.map((i) => CanvasItem.fromJson(i)).toList(),
  );
}

abstract class CanvasItem {
  String id;
  double x;
  double y;
  double width;
  double height;
  bool isLocked = false;
  
  CanvasItem(this.id, this.x, this.y, this.width, this.height, {this.isLocked = false});
  CanvasItem copy();

  Map<String, dynamic> toJson();
  
  factory CanvasItem.fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'text') return TextItem.fromJson(json);
    if (json['type'] == 'image') return ImageItem.fromJson(json);
    if (json['type'] == 'audio') return AudioItem.fromJson(json);
    throw Exception('Unknown CanvasItem type: ${json['type']}');
  }
}

class ImageItem extends CanvasItem {
  Uint8List imageBytes;
  ImageItem(String id, double x, double y, double width, double height, this.imageBytes, {super.isLocked}) 
    : super(id, x, y, width, height);

  @override
  ImageItem copy() => ImageItem(
    id, x, y, width, height, imageBytes, isLocked: isLocked
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': 'image',
    'id': id, 'x': x, 'y': y, 'width': width, 'height': height, 'isLocked': isLocked,
    'imageBytes': base64Encode(imageBytes),
  };
  
  factory ImageItem.fromJson(Map<String, dynamic> json) => ImageItem(
    json['id'], (json['x'] as num).toDouble(), (json['y'] as num).toDouble(),
    (json['width'] as num).toDouble(), (json['height'] as num).toDouble(),
    base64Decode(json['imageBytes']),
    isLocked: json['isLocked'] ?? false,
  );
}

class TextItem extends CanvasItem {
  String text;
  double fontSize;
  TextItem(String id, double x, double y, double width, double height, this.text, {this.fontSize = 16, super.isLocked}) 
    : super(id, x, y, width, height);

  @override
  TextItem copy() => TextItem(
    id, x, y, width, height, text, fontSize: fontSize, isLocked: isLocked
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': 'text',
    'id': id, 'x': x, 'y': y, 'width': width, 'height': height, 'isLocked': isLocked,
    'text': text, 'fontSize': fontSize,
  };
  
  factory TextItem.fromJson(Map<String, dynamic> json) => TextItem(
    json['id'], (json['x'] as num).toDouble(), (json['y'] as num).toDouble(),
    (json['width'] as num).toDouble(), (json['height'] as num).toDouble(),
    json['text'],
    fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16,
    isLocked: json['isLocked'] ?? false,
  );
}

class AudioItem extends CanvasItem {
  int durationSeconds;
  AudioItem(String id, double x, double y, double width, double height, this.durationSeconds, {super.isLocked}) 
    : super(id, x, y, width, height);

  @override
  AudioItem copy() => AudioItem(
    id, x, y, width, height, durationSeconds, isLocked: isLocked
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': 'audio',
    'id': id, 'x': x, 'y': y, 'width': width, 'height': height, 'isLocked': isLocked,
    'durationSeconds': durationSeconds,
  };
  
  factory AudioItem.fromJson(Map<String, dynamic> json) => AudioItem(
    json['id'], (json['x'] as num).toDouble(), (json['y'] as num).toDouble(),
    (json['width'] as num).toDouble(), (json['height'] as num).toDouble(),
    json['durationSeconds'] as int,
    isLocked: json['isLocked'] ?? false,
  );
}
