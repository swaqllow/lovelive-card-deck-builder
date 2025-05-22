// lib/models/card/base_card.dart
import '../enums/series_name.dart';
import '../enums/unit_name.dart';

abstract class BaseCard {
  final int id;               // カード番号
  final String cardCode;      // カード識別コード（構築上の同一カードを示す）
  final String rarity;        // レアリティ
  final String productSet;    // 収録商品
  final String name;          // 名前
  final SeriesName series;    // シリーズ名
  final UnitName? unit;       // ユニット
  final String imageUrl;      // イラストURL

  BaseCard({
    required this.id,
    required this.cardCode,
    required this.rarity,
    required this.productSet,
    required this.name,
    required this.series,
    this.unit,
    required this.imageUrl,
  });

  // JSON変換の抽象メソッド
  Map<String, dynamic> toJson();
  
  // カードタイプを返すゲッター
  String get cardType;
  
  // 構築上の同一性を判断するメソッド
  bool isSameCardForDeckBuilding(BaseCard other) {
    return cardCode == other.cardCode;
  }
}