enum CardType {
  member,   // メンバーカード
  live,     // ライブカード
  energy;   // エネルギーカード
}

extension CardTypeExtension on CardType {
  String get displayName {
    switch (this) {
      case CardType.member:
        return 'メンバー';
      case CardType.live:
        return 'ライブ';
      case CardType.energy:
        return 'エネルギー';
    }
  }
  
  String get description {
    switch (this) {
      case CardType.member:
        return 'デッキに入れて使用するメンバーカード。ブレードハートの基本コストなどが記載されています。';
      case CardType.live:
        return 'ライブステップで使用するためのカード。ライブスキルで特殊効果を発動します。';
      case CardType.energy:
        return 'エネルギーデッキを構成するカード。';
    }
  }
  
  // アイコンの取得
  String get iconPath {
    return 'assets/icons/card_type_$name.png';
  }
  
  // 日本語名からCardTypeを取得するstaticメソッド
  static CardType fromJapaneseName(String name) {
    switch (name) {
      case 'メンバー':
        return CardType.member;
      case 'ライブ':
        return CardType.live;
      case 'エネルギー':
        return CardType.energy;
      default:
        return CardType.member; // デフォルト値
    }
  }
}