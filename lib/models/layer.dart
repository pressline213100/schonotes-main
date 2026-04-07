import 'stroke.dart';

class LayerData {
  String id;
  String name;
  bool isVisible;
  bool isLocked;
  List<Stroke> strokes;
  
  LayerData({
    required this.id,
    required this.name,
    this.isVisible = true,
    this.isLocked = false,
    List<Stroke>? strokes,
  }) : strokes = strokes ?? [];

  LayerData copy() {
    return LayerData(
      id: id,
      name: name,
      isVisible: isVisible,
      isLocked: isLocked,
      strokes: strokes.map((s) => s.copy()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isVisible': isVisible,
    'isLocked': isLocked,
    'strokes': strokes.map((s) => s.toJson()).toList(),
  };

  factory LayerData.fromJson(Map<String, dynamic> json) => LayerData(
    id: json['id'],
    name: json['name'],
    isVisible: json['isVisible'] ?? true,
    isLocked: json['isLocked'] ?? false,
    strokes: (json['strokes'] as List?)?.map((s) => Stroke.fromJson(s)).toList(),
  );
}
