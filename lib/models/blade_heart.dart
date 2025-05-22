// lib/models/blade_heart.dart
import 'enums/blade_heart.dart';

class BladeHeart {
  // タイプごとの数量をマップで管理
  final Map<BladeHeartColor, int> quantities;
  
  BladeHeart({
    required this.quantities,
  });
  
  // 特定のタイプを持っているかチェック
  bool hasType(BladeHeartType type) {
    return quantities.containsKey(type) && quantities[type]! > 0;
  }
  
  // 特定のタイプの数量を取得
  int quantityOf(BladeHeartType type) {
    return quantities[type] ?? 0;
  }
  
  // 種類の総数を取得
  int get typeCount {
    return quantities.keys.length;
  }
  
  // JSON関連メソッド
  Map<String, dynamic> toJson() {
    final Map<String, int> jsonMap = {};
    quantities.forEach((type, quantity) {
      jsonMap[type.toString().split('.').last] = quantity;
    });
    return {'quantities': jsonMap};
  }
  
  factory BladeHeart.fromJson(Map<String, dynamic> json) {
    final jsonQuantities = json['quantities'] as Map<String, dynamic>? ?? {};
    final quantities = <BladeHeartColor, int>{};
    
    jsonQuantities.forEach((typeStr, quantity) {
      final type = BladeHeartColor.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr,
        orElse: () => BladeHeartColor.normalPink, // デフォルト値
      );
      quantities[type] = quantity as int;
    });
    
    return BladeHeart(quantities: quantities);
  }
}