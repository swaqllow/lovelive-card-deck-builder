// lib/models/card/member_card.dart
import 'base_card.dart';
import '../enums/heart_color.dart';
import '../enums/blade_heart.dart';
import '../enums/unit_name.dart';
import '../enums/series_name.dart';
import '../heart.dart';
import '../blade_heart.dart';
import 'dart:convert';

class MemberCard extends BaseCard {
  final List<Heart> hearts;           // ハート
  final int blades;                // ブレード
  final BladeHeart bladeHearts; // ブレードハート
  final String effect;                // 効果
  final int cost;                     // コスト（メンバーカード固有）

  MemberCard({
    required super.id,
    required super.cardCode,
    required super.rarity,
    required super.productSet,
    required super.name,
    required super.series,
    super.unit,
    required super.imageUrl,
    required this.cost,               // コストパラメータ
    required this.hearts,
    required this.blades,
    required this.bladeHearts,
    required this.effect,
  });

  @override
  String get cardType => 'member';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_code': cardCode,
      'rarity': rarity,
      'product_set': productSet,
      'name': name,
      'series': series.toString().split('.').last,
      'unit': unit?.toString().split('.').last,
      'image_url': imageUrl,
      'card_type': cardType,
      'hearts': hearts.map((heart) => heart.toJson()).toList(),
      'blades': blades,
      'blade_hearts': bladeHearts.toJson(),
      'effect': effect,
    };
  }

  factory MemberCard.fromJson(Map<String, dynamic> json) {
    // シリーズ名の変換
    final seriesStr = json['series'] as String;
    final series = SeriesName.values.firstWhere(
      (e) => e.toString().split('.').last == seriesStr,
      orElse: () => SeriesName.lovelive,
    );

    // ユニット名の変換（存在する場合）
    UnitName? unit;
    if (json['unit'] != null) {
      final unitStr = json['unit'] as String;
      final matchingUnits = UnitName.values.where(
        (e) => e.toString().split('.').last == unitStr,
      );
      unit = matchingUnits.isNotEmpty ? matchingUnits.first : null;
    }

    // ハートの変換
    final List<Heart> hearts = [];
    if (json['hearts'] != null) {
      final heartsList = json['hearts'] as List<dynamic>;
      hearts.addAll(heartsList.map((e) => Heart.fromJson(e as Map<String, dynamic>)));
    }

    // ブレードの変換
    final blades = json['blades'] as int? ?? 0;

    // ブレードハートの変換
    final BladeHeart bladeHearts = BladeHeart(quantities: {});
    if (json['blade_hearts'] != null) {
      final bladeHeartsList = json['blade_hearts'] as List<dynamic>;
      bladeHeartsList.map((e) => BladeHeart.fromJson(e as Map<String, dynamic>));
    }

    return MemberCard(
      id: json['id'] as int,
      cardCode: json['card_code'] as String,
      rarity: json['rarity'] as String,
      productSet: json['product_set'] as String,
      name: json['name'] as String,
      series: series,
      unit: unit,
      imageUrl: json['image_url'] as String? ?? '',
      cost: json['cost'] as int? ?? 0, 
      hearts: hearts,
      blades: blades,
      bladeHearts: bladeHearts,
      effect: json['effect'] as String? ?? '',
    );
  }


    MemberCard.fromMap(Map<String, dynamic> map)
    : cost = map['cost'] ?? 0,
      hearts = _parseHearts(map['hearts']), // data_jsonから取得
      blades = map['blades'] ?? 0,
      bladeHearts = _parseBladeHearts(map['bladeHearts'] ?? map['blade_hearts']),
      effect = map['effect'] ?? '',
      super(
        id: map['id'] ?? 0,
        cardCode: map['card_code'] ?? '',
        rarity: map['rarity'] ?? '',
        productSet: map['product_set'] ?? '',
        name: map['name'] ?? '',
        series: _parseSeriesName(map['series']),
        unit: _parseUnitName(map['unit']),
        imageUrl: map['image_url'] ?? '',
      );
  
  // heartsパース処理の修正
  static List<Heart> _parseHearts(dynamic heartsData) {
    print('=== Hearts解析開始 ===');
    print('入力データ: $heartsData');
    print('データ型: ${heartsData.runtimeType}');
    
    if (heartsData == null) {
      print('heartsData is null');
      return [];
    }
    
    try {
      // 文字列からパース（JSON文字列の場合）
      if (heartsData is String) {
        print('JSON文字列からパース');
        final decoded = jsonDecode(heartsData);
        print('デコード結果: $decoded');
        return _parseHearts(decoded);  // 再帰処理
      }
      
      // 既にListの場合
      if (heartsData is List) {
        print('Listからパース: ${heartsData.length}個');
        final result = heartsData.map((heart) {
          print('単一ハート処理: $heart (型: ${heart.runtimeType})');
          
          if (heart is Map) {
            final colorValue = heart['color'] ?? heart['colorName'];
            final color = _parseHeartColor(colorValue);
            print('  -> 色: $color');
            return Heart(color: color);
          } else if (heart is String) {
            // 文字列の場合（例: "HeartColor.red"）
            final color = _parseHeartColor(heart);
            print('  -> 色: $color');
            return Heart(color: color);
          }
          return Heart(color: HeartColor.any);
        }).toList();
        
        print('パース結果: ${result.length}個のハート');
        return result;
      }
      
      // Mapの場合（色->数量）
      if (heartsData is Map) {
        print('Mapからパース');
        final List<Heart> hearts = [];
        heartsData.forEach((key, value) {
          print('処理中: $key -> $value');
          final color = _parseHeartColor(key.toString());
          final count = value is int ? value : int.tryParse(value.toString()) ?? 0;
          print('  -> 色: $color, 数: $count');
          
          for (int i = 0; i < count; i++) {
            hearts.add(Heart(color: color));
          }
        });
        print('Mapパース結果: ${hearts.length}個のハート');
        return hearts;
      }
      
    } catch (e, stackTrace) {
      print('ハートパースエラー: $e');
      print('スタックトレース: $stackTrace');
    }
    
    print('デフォルト値を返す');
    return [];
  }
  
  // bladeHeartsパース処理の修正
  static BladeHeart _parseBladeHearts(dynamic bladeData) {
    print('=== BladeHearts解析開始 ===');
    print('入力データ: $bladeData');
    print('データ型: ${bladeData.runtimeType}');
    
    if (bladeData == null) {
      print('bladeData is null');
      return BladeHeart(quantities: {});
    }
    
    try {
      // 文字列からパース
      if (bladeData is String) {
        print('JSON文字列からパース');
        final decoded = jsonDecode(bladeData);
        print('デコード結果: $decoded');
        return _parseBladeHearts(decoded);  // 再帰処理
      }
      
      // Map形式
       if (bladeData is Map) {
        print('Mapからパース');
        final Map<BladeHeartColor, int> quantities = {};
        
        // quantitiesキーがある場合はその中身を処理
        if (bladeData.containsKey('quantities')) {
          final quantitiesMap = bladeData['quantities'];
          if (quantitiesMap is Map && quantitiesMap.isNotEmpty) {
            quantitiesMap.forEach((key, value) {
              final color = _parseBladeHeartColor(key.toString());
              final quantity = value is int ? value : 1;
              
              if (color != null) {
                quantities[color] = quantity;
                print('  -> 追加: $color x $quantity');
              }
            });
          } else {
            print('  -> 空のquantitiesマップ、デフォルト値は追加しない');
          }
        }
    
    final result = BladeHeart(quantities: quantities);
    print('Mapパース結果: ${quantities.keys.join(', ')}');
    return result;
  }
      
    } catch (e, stackTrace) {
      print('ブレードハートパースエラー: $e');
      print('スタックトレース: $stackTrace');
    }
    
    print('デフォルト値を返す');
    return BladeHeart(quantities: {});
  }
  
  // HeartColorパースヘルパー
static HeartColor _parseHeartColor(String? colorStr) {
  if (colorStr == null) return HeartColor.any;
  
  print('HeartColor解析: $colorStr');
  
  // カラーを小文字に統一して比較
  final color = colorStr.toLowerCase();
  
  // 直接のenum名比較
  for (var heartColor in HeartColor.values) {
    if (heartColor.toString().toLowerCase().contains(color)) {
      return heartColor;
    }
  }
  
  // 色名による比較（英語）
  switch (color) {
    case 'red': return HeartColor.red;
    case 'yellow': return HeartColor.yellow;
    case 'purple': return HeartColor.purple;
    case 'pink': return HeartColor.pink;
    case 'green': return HeartColor.green;
    case 'blue': return HeartColor.blue;
    default: return HeartColor.any;
  }
}
  static BladeHeartColor? _parseBladeHeartColor(String? colorStr) {
    if (colorStr == null) return null;
    
    print('BladeHeartColor解析: $colorStr');
    
    try {
      return BladeHeartColor.values.firstWhere(
        (e) => e.toString() == colorStr,
        orElse: () => BladeHeartColor.normalPink,  
      );
    } catch (e) {
      print('BladeHeartColor解析失敗: $e');
      return null;
    }
  }

  // SeriesNameパースヘルパー
  static SeriesName _parseSeriesName(String seriesStr) {
    return SeriesName.values.firstWhere(
      (e) => e.toString().split('.').last == seriesStr,
      orElse: () => SeriesName.lovelive,
    );
  }
  // UnitNameパースヘルパー
  static UnitName? _parseUnitName(String? unitStr) {
    if (unitStr == null) return null;
    return UnitName.values.firstWhere(
      (e) => e.toString().split('.').last == unitStr,
      orElse: () => UnitName.bibi,
    );
  }
}
