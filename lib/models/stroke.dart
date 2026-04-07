import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

enum ToolType { pen, highlighter, eraser, lasso, text, image, straightLine, circle, tape, select }
enum EraserType { object, pixel }

class PointData {
  final Offset offset;
  final double pressure;
  PointData(this.offset, this.pressure);

  Map<String, dynamic> toJson() => {
    'dx': offset.dx,
    'dy': offset.dy,
    'pressure': pressure,
  };

  factory PointData.fromJson(Map<String, dynamic> json) => PointData(
    Offset((json['dx'] as num).toDouble(), (json['dy'] as num).toDouble()),
    (json['pressure'] as num).toDouble(),
  );
}

class Stroke {
  final String id;
  Color color;
  double strokeWidth;
  ToolType toolType;
  List<PointData> points;
  double penThinning;
  
  // Selection & transforms
  bool isSelected = false;
  Offset transformOffset = Offset.zero;
  bool isTapeHidden = false;

  // Cached path
  Path? _cachedPath;

  Stroke({
    required this.id,
    required this.color,
    required this.strokeWidth,
    required this.toolType,
    required this.points,
    this.penThinning = 0.6,
  });

  Path get path {
    if (_cachedPath != null) return _cachedPath!;
    if (toolType == ToolType.straightLine) {
       _cachedPath = _generateStraightLine();
    } else if (toolType == ToolType.circle) {
       _cachedPath = _generateCircle();
    } else {
       _cachedPath = _generateFreehandPath();
    }
    return _cachedPath!;
  }

  void invalidatePath() {
    _cachedPath = null;
  }
  
  Path _generateStraightLine() {
    Path p = Path();
    if (points.isEmpty) return p;
    // For standard rendering, straight lines don't use perfect_freehand fill, so we can mock a thin fill or just stroke it
    p.moveTo(points.first.offset.dx, points.first.offset.dy);
    p.lineTo(points.last.offset.dx, points.last.offset.dy);
    return p;
  }
  
  Path _generateCircle() {
    Path p = Path();
    if (points.isEmpty) return p;
    final start = points.first.offset;
    final end = points.last.offset;
    final radius = (start - end).distance / 2;
    final center = Offset((start.dx + end.dx)/2, (start.dy + end.dy)/2);
    p.addOval(Rect.fromCircle(center: center, radius: radius));
    return p;
  }

  Path _generateFreehandPath() {
    if (points.isEmpty) return Path();
    
    // convert to perfect_freehand PointVector
    final inputPoints = points.map((p) => PointVector(p.offset.dx, p.offset.dy, p.pressure)).toList();
    
    // Customize freehand algorithm
    final options = StrokeOptions(
      size: strokeWidth,
      thinning: toolType == ToolType.pen ? penThinning : 0.0,
      smoothing: 0.5,
      streamline: 0.5,
      simulatePressure: toolType == ToolType.pen,
      isComplete: false,
    );
    
    final outlinePoints = getStroke(inputPoints, options: options);
    
    final path = Path();
    if (outlinePoints.isEmpty) return path;
    
    path.moveTo(outlinePoints[0].dx, outlinePoints[0].dy);
    for (int i = 1; i < outlinePoints.length - 1; i++) {
       final p0 = outlinePoints[i];
       final p1 = outlinePoints[i + 1];
       path.quadraticBezierTo(p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
    }
    path.lineTo(outlinePoints.last.dx, outlinePoints.last.dy);
    path.close();
    
    return path;
  }

  Rect get bounds {
    if (points.isEmpty) return Rect.zero;
    double minX = points[0].offset.dx;
    double maxX = points[0].offset.dx;
    double minY = points[0].offset.dy;
    double maxY = points[0].offset.dy;
    for (var p in points) {
      if (p.offset.dx < minX) minX = p.offset.dx;
      if (p.offset.dx > maxX) maxX = p.offset.dx;
      if (p.offset.dy < minY) minY = p.offset.dy;
      if (p.offset.dy > maxY) maxY = p.offset.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY).shift(transformOffset).inflate(strokeWidth);
  }

  bool intersectsRect(Rect rect) {
    return bounds.overlaps(rect);
  }

  Stroke copy() {
    return Stroke(
      id: id,
      color: color,
      strokeWidth: strokeWidth,
      toolType: toolType,
      points: List.from(points),
      penThinning: penThinning,
    )..isSelected = isSelected
     ..transformOffset = transformOffset
     ..isTapeHidden = isTapeHidden;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'color': color.value,
    'strokeWidth': strokeWidth,
    'toolType': toolType.index,
    'points': points.map((p) => p.toJson()).toList(),
    'penThinning': penThinning,
    'isSelected': isSelected,
    'transformOffset': {'dx': transformOffset.dx, 'dy': transformOffset.dy},
    'isTapeHidden': isTapeHidden,
  };

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      id: json['id'],
      color: Color(json['color']),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      toolType: ToolType.values[json['toolType']],
      points: (json['points'] as List).map((p) => PointData.fromJson(p)).toList(),
      penThinning: (json['penThinning'] as num?)?.toDouble() ?? 0.6,
    )..isSelected = json['isSelected'] ?? false
     ..transformOffset = Offset(
       ((json['transformOffset']?['dx'] ?? 0) as num).toDouble(),
       ((json['transformOffset']?['dy'] ?? 0) as num).toDouble()
     )
     ..isTapeHidden = json['isTapeHidden'] ?? false;
  }
}
