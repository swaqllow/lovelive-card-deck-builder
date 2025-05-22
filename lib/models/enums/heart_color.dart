enum HeartColor {
  red,
  yellow, 
  purple,
  pink,
  green,
  blue,
  any;
  
  // カラーコードの取得
  String get colorCode {
    switch (this) {
      case HeartColor.red:
        return '#FF5555';
      case HeartColor.yellow:
        return '#FFDD44';
      case HeartColor.purple:
        return '#AA66CC';
      case HeartColor.pink:
        return '#FF88BB';
      case HeartColor.green:
        return '#66CC77';
      case HeartColor.blue:
        return '#5599FF';
      case HeartColor.any:
        return '#CCCCCC';
    }
  }
}

extension HeartColorExtension on HeartColor {
  String get displayName {
    switch (this) {
      case HeartColor.red:
        return '赤';
      case HeartColor.yellow:
        return '黄';
      case HeartColor.purple:
        return '紫';
      case HeartColor.pink:
        return 'ピンク';
      case HeartColor.green:
        return '緑';
      case HeartColor.blue:
        return '青';
      case HeartColor.any:
        return '不定色';
    }
  }
  
  // 日本語の名前からHeartColorを取得するstaticメソッド
  static HeartColor fromJapaneseName(String name) {
    switch (name) {
      case '赤':
        return HeartColor.red;
      case '黄':
        return HeartColor.yellow;
      case '紫':
        return HeartColor.purple;
      case 'ピンク':
        return HeartColor.pink;
      case '緑':
        return HeartColor.green;
      case '青':
        return HeartColor.blue;
      case '不定色':
        return HeartColor.any;
      default:
        return HeartColor.any;
    }
  }
  
  // アイコンの取得
  String get iconPath {
    return 'assets/icons/heart_$name.png';
  }
}