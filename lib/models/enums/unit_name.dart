import 'series_name.dart';

enum UnitName {
  // μ's (ミューズ)のユニット
  bibi,
  lillyWhite,
  printemps,
  //muse,  // μ's全体

  // Aqours (アクア)のユニット
  guiltykiss,
  cyaron,
  azalea,
  //aqours, // Aqours全体

  // 虹ヶ咲学園のユニット
  azuna,
  diverdiva,
  qu4rtz,
  r3birth,
  //nijigasaki, // 虹ヶ咲全体

  // Liella! (リエラ)のユニット
  catchu,
  kaleidoscore,
  syncri5e,
  sunnypassion,
  //liella, // Liella!全体

  // 蓮ノ空女学院のユニット
  cerisebouquet,
  dollchestra,
  mirapa,
  edelnote,
  //hasunosora, // 蓮ノ空全体
  
  // グループに属さない
  none;
  
  // どのシリーズに属するかを取得
  SeriesName get series {
    switch (this) {
      case UnitName.bibi:
      case UnitName.lillyWhite:
      case UnitName.printemps:
        return SeriesName.lovelive;
      
      case UnitName.guiltykiss:
      case UnitName.cyaron:
      case UnitName.azalea:
        return SeriesName.sunshine;
      
      case UnitName.azuna:
      case UnitName.diverdiva:
      case UnitName.qu4rtz:
      case UnitName.r3birth:
        return SeriesName.nijigasaki;
      
      case UnitName.catchu:
      case UnitName.kaleidoscore:
      case UnitName.syncri5e:
      case UnitName.sunnypassion:
        return SeriesName.superstar;
      
      case UnitName.cerisebouquet:
      case UnitName.dollchestra:
      case UnitName.mirapa:
      case UnitName.edelnote:
        return SeriesName.hasunosoraGakuin;
      
      case UnitName.none:
        return SeriesName.lovelive; // デフォルト値
    }
  }
}

extension UnitNameExtension on UnitName {
  String get displayName {
    switch (this) {
      case UnitName.bibi:
        return 'BiBi';
      case UnitName.lillyWhite:
        return 'lily white';
      case UnitName.printemps:
        return 'Printemps';
      
      case UnitName.guiltykiss:
        return 'Guilty Kiss';
      case UnitName.cyaron:
        return 'CYaRon!';
      case UnitName.azalea:
        return 'AZALEA';
      
      case UnitName.azuna:
        return 'A・ZU・NA';
      case UnitName.diverdiva:
        return 'DiverDiva';
      case UnitName.qu4rtz:
        return 'QU4RTZ';
      case UnitName.r3birth:
        return 'R3BIRTH';
      
      case UnitName.catchu:
        return 'Catchu!';
      case UnitName.kaleidoscore:
        return 'KALEIDOSCORE';
      case UnitName.syncri5e:
        return '5yncri5e';
      case UnitName.sunnypassion:
        return 'Sunny Passion';
      
      case UnitName.cerisebouquet:
        return 'スリーズブーケ';
      case UnitName.dollchestra:
        return 'DOLLCHESTRA';
      case UnitName.mirapa: 
        return 'みらくらパーク!';
      case UnitName.edelnote:
        return 'Edel Note';
      
      case UnitName.none:
        return '無所属';
    }
  }
  
  // ロゴのパスを取得
  String get logoPath {
    return 'assets/logos/unit_${name}_logo.png';
  }
  
  // 日本語名からUnitNameを取得するstaticメソッド
  static UnitName fromJapaneseName(String name) {
    // μ'sのユニット
    if (name.contains('BiBi')) return UnitName.bibi;
    if (name.contains('lily white')) return UnitName.lillyWhite;
    if (name.contains('Printemps')) return UnitName.printemps;
    //if (name.contains('μ\'s') || name.contains('ミューズ')) return UnitName.muse;
    
    // Aqoursのユニット
    if (name.contains('Guilty Kiss')) return UnitName.guiltykiss;
    if (name.contains('CYaRon')) return UnitName.cyaron;
    if (name.contains('AZALEA')) return UnitName.azalea;
    //if (name.contains('Aqours') || name.contains('アクア')) return UnitName.aqours;
    
    // 虹ヶ咲のユニット
    if (name.contains('A・ZU・NA') || name.contains('AZUNA')) return UnitName.azuna;
    if (name.contains('DiverDiva')) return UnitName.diverdiva;
    if (name.contains('QU4RTZ')) return UnitName.qu4rtz;
    if (name.contains('R3BIRTH')) return UnitName.r3birth;
    //if (name.contains('虹ヶ咲')) return UnitName.nijigasaki;
    
    // Liella!のユニット
    if (name.contains('Catchu')) return UnitName.catchu;
    if (name.contains('kaleidosore') ) return UnitName.kaleidoscore;
    if (name.contains('5yncri5e')) return UnitName.syncri5e;
    if (name.contains('Sunny Passion')) return UnitName.sunnypassion;
    //if (name.contains('Liella') || name.contains('リエラ')) return UnitName.liella;
    
    // 蓮ノ空のユニット
    if (name.contains('スリーズブーケ')) return UnitName.cerisebouquet;
    if (name.contains('DOLLCHESTRA')) return UnitName.dollchestra;
    if (name.contains('みらくらパーク')) return UnitName.mirapa;
    if (name.contains('Edel Note')) return UnitName.edelnote;
    //if (name.contains('蓮ノ空')) return UnitName.hasunosora;
    
    // 該当しない場合
    return UnitName.none;
  }
}