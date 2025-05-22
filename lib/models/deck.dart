// lib/models/deck.dart
import 'card/base_card.dart';
import 'card/member_card.dart';
import 'card/live_card.dart';
import 'card/energy_card.dart';
import 'card/card_factory.dart';

class Deck {
  int? id;
  String name;
  List<BaseCard> mainDeckCards; // メインデッキのカード（メンバーカードとライブカード）
  List<EnergyCard> energyDeckCards; // エネルギーデッキのカード
  String notes;
  
  Deck({
    this.id,
    required this.name,
    required this.mainDeckCards,
    required this.energyDeckCards,
    this.notes = '',
  });
  
  // メインデッキの全カード数を取得
  int get mainDeckSize => mainDeckCards.length;
  
  // エネルギーデッキのカード数を取得
  int get energyDeckSize => energyDeckCards.length;
  
  // メインデッキのメンバーカード数を取得
  int get memberCardCount => mainDeckCards.whereType<MemberCard>().length;
  
  // メインデッキのライブカード数を取得
  int get liveCardCount => mainDeckCards.whereType<LiveCard>().length;
  
  // デッキが有効かどうかをチェック（ゲームルールに準拠しているか）
  bool isValid() {
    // メインデッキが60枚（メンバーカード48枚、ライブカード12枚）
    final validMainDeckSize = mainDeckSize == 60;
    final validMemberCardCount = memberCardCount == 48;
    final validLiveCardCount = liveCardCount == 12;
    
    // エネルギーデッキが12枚
    final validEnergyDeckSize = energyDeckSize == 12;
    
    return validMainDeckSize && validMemberCardCount && validLiveCardCount && validEnergyDeckSize;
  }
  
  // JSONからデッキオブジェクトを生成
  factory Deck.fromJson(Map<String, dynamic> json) {
    // メインデッキカードの解析
    final mainDeckJsonList = json['main_deck_cards'] as List<dynamic>;
    final mainDeckCards = mainDeckJsonList.map((cardJson) {
      return CardFactory.createCardFromJson(cardJson);
    }).toList();
    
    // エネルギーデッキカードの解析
    final energyDeckJsonList = json['energy_deck_cards'] as List<dynamic>;
    final energyDeckCards = energyDeckJsonList.map((cardJson) {
      final card = CardFactory.createCardFromJson(cardJson);
      if (card is! EnergyCard) {
        throw FormatException('エネルギーデッキに不正なカードタイプが含まれています');
      }
      return card ;
    }).toList();
    
    return Deck(
      id: json['id'],
      name: json['name'],
      mainDeckCards: mainDeckCards,
      energyDeckCards: energyDeckCards,
      notes: json['notes'] ?? '',
    );
  }
  
  // デッキオブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'main_deck_cards': mainDeckCards.map((card) => card.toJson()).toList(),
      'energy_deck_cards': energyDeckCards.map((card) => card.toJson()).toList(),
      'notes': notes,
    };
  }
}