// lib/models/card/energy_card.dart
import 'base_card.dart';
import '../enums/series_name.dart';
import '../enums/unit_name.dart';

class EnergyCard extends BaseCard {
  EnergyCard({
    required super.id,
    required String cardCode,
    required super.rarity,
    required super.productSet,
    required super.name,
    required super.series,
    super.unit,
    required super.imageUrl,
  }) : super(
          cardCode: "ENERGY_CARD",
        );

  @override
  String get cardType => 'energy';

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
    };
  }

  factory EnergyCard.fromJson(Map<String, dynamic> json) {
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

    return EnergyCard(
      id: json['id'] as int,
      cardCode: json['card_code'] as String,
      rarity: json['rarity'] as String,
      productSet: json['product_set'] as String,
      name: json['name'] as String,
      series: series,
      unit: unit,
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
}