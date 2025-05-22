import 'package:flutter/material.dart';
import 'dart:math' as math;

class PieChartPainter extends CustomPainter {
  final Map<String, int> data;
  final Map<String, Color> colors;
  
  PieChartPainter({
    required this.data,
    required this.colors,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    final total = data.values.fold<int>(0, (sum, count) => sum + count);
    if (total <= 0) return;
    
    double startAngle = -math.pi / 2; // 12時の位置から開始
    
    data.forEach((key, value) {
      final sweepAngle = 2 * math.pi * value / total;
      final color = colors[key] ?? Colors.grey;
      
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;
      
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      
      startAngle += sweepAngle;
    });
  }
  
  @override
  bool shouldRepaint(PieChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.colors != colors;
  }
}