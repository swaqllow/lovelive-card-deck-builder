// lib/models/heart.dart
import 'enums/heart_color.dart';

class Heart {
  final HeartColor color;
  
  Heart({required this.color});
  
  Map<String, dynamic> toJson() {
    return {
      'color': color.toString().split('.').last,
    };
  }
  
  factory Heart.fromJson(Map<String, dynamic> json) {
    final colorStr = json['color'] as String;
    final color = HeartColor.values.firstWhere(
      (e) => e.toString().split('.').last == colorStr,
      orElse: () => HeartColor.any,
    );
    
    return Heart(color: color);
  }
}