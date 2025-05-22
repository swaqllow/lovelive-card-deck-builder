// lib/models/card/card_factory.dart
import 'base_card.dart';
import 'member_card.dart';
import 'live_card.dart';
import 'energy_card.dart';

class CardFactory {
  // JSONデータからカードインスタンスを作成
  static BaseCard createCardFromJson(Map<String, dynamic> json) {
    final cardType = json['card_type'] as String? ?? 'member';
    
    switch (cardType) {
      case 'member':
        return MemberCard.fromJson(json);
      case 'live':
        return LiveCard.fromJson(json);
      case 'energy':
        return EnergyCard.fromJson(json);
      default:
        throw ArgumentError('Unknown card type: $cardType');
    }
  }
  
  // カードのタイプを判定
  static String getCardType(BaseCard card) {
    if (card is MemberCard) return 'member';
    if (card is LiveCard) return 'live';
    if (card is EnergyCard) return 'energy';
    return 'unknown';
  }
}