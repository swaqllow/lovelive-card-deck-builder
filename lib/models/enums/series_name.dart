enum SeriesName {
  lovelive,       // μ's (ミューズ)
  sunshine,       // Aqours (アクア)
  nijigasaki,     // 虹ヶ咲学園スクールアイドル同好会
  superstar,      // Liella! (リエラ)
  hasunosoraGakuin;  // 蓮ノ空女学院スクールアイドルクラブ
  
  // ルール上のシリーズ番号を取得
  int get seriesNumber {
    switch (this) {
      case SeriesName.lovelive:
        return 1;
      case SeriesName.sunshine:
        return 2;
      case SeriesName.nijigasaki:
        return 3;
      case SeriesName.superstar:
        return 4;
      case SeriesName.hasunosoraGakuin:
        return 5;
    }
  }
  // 日本語名からSeriesNameを取得するstaticメソッド
  static SeriesName fromJapaneseName(String name) {
    if (name.contains('μ\'s') || name.contains('ミューズ') || name.contains('ラブライブ！') && !name.contains('サンシャイン') && !name.contains('虹ヶ咲') && !name.contains('スーパースター') && !name.contains('蓮ノ空')) {
      return SeriesName.lovelive;
    } else if (name.contains('Aqours') || name.contains('アクア') || name.contains('サンシャイン')) {
      return SeriesName.sunshine;
    } else if (name.contains('虹ヶ咲')|| name.contains('ニジガク') ) {
      return SeriesName.nijigasaki;
    } else if (name.contains('Liella') || name.contains('リエラ') || name.contains('スーパースター')) {
      return SeriesName.superstar;
    } else if (name.contains('蓮ノ空')) {
      return SeriesName.hasunosoraGakuin;
    } else {
      // デフォルト値
      return SeriesName.lovelive;
    }
  }
}

extension SeriesNameExtension on SeriesName {
  String get displayName {
    switch (this) {
      case SeriesName.lovelive:
        return 'ラブライブ！';
      case SeriesName.sunshine:
        return 'ラブライブ！サンシャイン!!';
      case SeriesName.nijigasaki:
        return 'ラブライブ！虹ヶ咲学園スクールアイドル同好会';
      case SeriesName.superstar:
        return 'ラブライブ！スーパースター!!!';
      case SeriesName.hasunosoraGakuin:
        return '蓮ノ空女学院スクールアイドルクラブ';
    }
  }
  
  String get shortName {
    switch (this) {
      case SeriesName.lovelive:
        return 'μ\'s';
      case SeriesName.sunshine:
        return 'Aqours';
      case SeriesName.nijigasaki:
        return '虹ヶ咲';
      case SeriesName.superstar:
        return 'Liella!';
      case SeriesName.hasunosoraGakuin:
        return '蓮ノ空';
    }
  }
  
  // ロゴのパスを取得
  String get logoPath {
    return 'assets/logos/${name}_logo.png';
  }
  

}