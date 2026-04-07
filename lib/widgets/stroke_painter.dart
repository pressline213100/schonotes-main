import 'package:flutter/material.dart';
import '../models/stroke.dart';

class StrokePainter extends CustomPainter {
  final List<Stroke> strokes;
  final ToolType activeTool;
  StrokePainter(this.strokes, this.activeTool);

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      canvas.save();
      canvas.translate(stroke.transformOffset.dx, stroke.transformOffset.dy);

      final paint = Paint()
        ..color = stroke.color
        ..style = PaintingStyle.fill;
        
      if (stroke.toolType == ToolType.highlighter) {
         paint.blendMode = BlendMode.multiply;
      } else if (stroke.toolType == ToolType.lasso) {
         paint.color = Colors.blueAccent.withValues(alpha: 0.1);
         canvas.drawPath(stroke.path, paint);
         
         final borderPaint = Paint()..color=Colors.blueAccent..style=PaintingStyle.stroke..strokeWidth=2;
         canvas.drawPath(stroke.path, borderPaint);
      }
      
      if (stroke.toolType == ToolType.tape) {
         if (stroke.isTapeHidden) {
           paint.color = stroke.color.withOpacity(0.1);
           canvas.drawPath(stroke.path, paint);
           final dashPaint = Paint()
             ..color = stroke.color.withOpacity(0.5)
             ..style = PaintingStyle.stroke
             ..strokeWidth = 1.0;
           canvas.drawPath(stroke.path, dashPaint);
         } else {
           paint.color = stroke.color.withOpacity(1.0);
           canvas.drawPath(stroke.path, paint);
         }
      } else if (stroke.toolType != ToolType.lasso) {
         canvas.drawPath(stroke.path, paint);
      }
      
      if (stroke.isSelected) {
        final bounds = stroke.bounds.shift(-stroke.transformOffset);
        final boxPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawRect(bounds.inflate(4), boxPaint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; 
}

// Just exposing the painter for use in drawing_board.dart, the rest of drawing_board can be the same.
