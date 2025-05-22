import 'heart_color.dart';

enum BladeHeartColor {
  // 通常タイプ（6色）
  normalRed,
  normalYellow,
  normalPurple,
  normalPink,
  normalGreen,
  normalBlue,
  
  // 特殊タイプ
  utility,
  draw,
  scoreUp;
  
  // ブレードハートのタイプを取得
  BladeHeartType get type {
    if (name.startsWith('normal')) {
      return BladeHeartType.normal;
    } else if (name == 'utility') {
      return BladeHeartType.utility;
    } else if (name == 'draw') {
      return BladeHeartType.draw;
    } else if (name == 'scoreUp') {
      return BladeHeartType.scoreUp;
    } else {
      // デフォルト値
      return BladeHeartType.normal;
    }
  }
  
  // ブレードハートの色を取得
  HeartColor get color {
    if (name == 'normalRed') {
      return HeartColor.red;
    } else if (name == 'normalYellow') {
      return HeartColor.yellow;
    } else if (name == 'normalPurple') {
      return HeartColor.purple;
    } else if (name == 'normalPink') {
      return HeartColor.pink;
    } else if (name == 'normalGreen') {
      return HeartColor.green;
    } else if (name == 'normalBlue') {
      return HeartColor.blue;
    } else {
    // 特殊タイプには不定色を割り当て
    return HeartColor.any;
  }
  }
  
  // タイプの説明文を取得
  String get description {
    switch (type) {
      case BladeHeartType.normal:
        return '通常の${color.displayName}色ブレードハート';
      case BladeHeartType.utility:
        return '任意色のブレードハート';
      case BladeHeartType.draw:
        return 'カードを引くことができるブレードハート';
      case BladeHeartType.scoreUp:
        return 'スコアを上げることができるブレードハート';
    }
  }
  
}

// ブレードハートのタイプ（メタ分類）
enum BladeHeartType {
  normal,
  utility,
  draw,
  scoreUp;
}

extension BladeHeartExtension on BladeHeartColor {
  String get displayName {
    switch (this) {
      case BladeHeartColor.normalRed:
        return '通常赤';
      case BladeHeartColor.normalYellow:
        return '通常黄';
      case BladeHeartColor.normalPurple:
        return '通常紫';
      case BladeHeartColor.normalPink:
        return '通常桃';
      case BladeHeartColor.normalGreen:
        return '通常緑';
      case BladeHeartColor.normalBlue:
        return '通常青';
      case BladeHeartColor.utility:
        return 'ユーティリティ';
      case BladeHeartColor.draw:
        return 'ドロー';
      case BladeHeartColor.scoreUp:
        return 'スコアアップ';
    }
  }
  
  // 日本語の名前からBladeHeartを取得するstaticメソッド
  static BladeHeartColor fromJapaneseName(String name) {
    switch (name) {
      case '通常赤':
        return BladeHeartColor.normalRed;
      case '通常黄':
        return BladeHeartColor.normalYellow;
      case '通常紫':
        return BladeHeartColor.normalPurple;
      case '通常桃':
        return BladeHeartColor.normalPink;
      case '通常緑':
        return BladeHeartColor.normalGreen;
      case '通常青':
        return BladeHeartColor.normalBlue;
      case 'ユーティリティ':
        return BladeHeartColor.utility;
      case 'ドロー':
        return BladeHeartColor.draw;
      case 'スコアアップ':
        return BladeHeartColor.scoreUp;
      default:
        return BladeHeartColor.normalRed; // デフォルト値
    }
  }
  
  // アイコンの取得
  String get iconPath {
    if (type == BladeHeartType.normal) {
      return 'assets/icons/blade_heart_normal_${color.name}.png';
    } else {
      return 'assets/icons/blade_heart_$name.png';
    }
  }
  
  // タイプと色の組み合わせからBladeHeartを取得するstaticメソッド
  static BladeHeartColor fromTypeAndColor(BladeHeartType type, HeartColor color) {
    if (type == BladeHeartType.normal) {
      switch (color) {
        case HeartColor.red:
          return BladeHeartColor.normalRed;
        case HeartColor.yellow:
          return BladeHeartColor.normalYellow;
        case HeartColor.purple:
          return BladeHeartColor.normalPurple;
        case HeartColor.pink:
          return BladeHeartColor.normalPink;
        case HeartColor.green:
          return BladeHeartColor.normalGreen;
        case HeartColor.blue:
          return BladeHeartColor.normalBlue;
        default:
          return BladeHeartColor.normalRed; // デフォルト
      }
    } else if (type == BladeHeartType.utility) {
      return BladeHeartColor.utility;
    } else if (type == BladeHeartType.draw) {
      return BladeHeartColor.draw;
    } else if (type == BladeHeartType.scoreUp) {
      return BladeHeartColor.scoreUp;
    } else {
      return BladeHeartColor.normalRed; // デフォルト
    }
  }
}

extension BladeHeartTypeExtension on BladeHeartType {
  String get displayName {
    switch (this) {
      case BladeHeartType.normal:
        return '通常';
      case BladeHeartType.utility:
        return 'ユーティリティ';
      case BladeHeartType.draw:
        return 'ドロー';
      case BladeHeartType.scoreUp:
        return 'スコアアップ';
    }
  }
  
  // 日本語の名前からBladeHeartTypeを取得するstaticメソッド
  static BladeHeartType fromJapaneseName(String name) {
    if (name.startsWith('通常')) {
      return BladeHeartType.normal;
    }
    
    switch (name) {
      case 'ユーティリティ':
        return BladeHeartType.utility;
      case 'ドロー':
        return BladeHeartType.draw;
      case 'スコアアップ':
        return BladeHeartType.scoreUp;
      default:
        return BladeHeartType.normal;
    }
  }
}