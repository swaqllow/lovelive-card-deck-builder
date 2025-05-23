// ================================================
// PostgreSQL対応アダプター（実際のEnum対応版）
// ================================================

// lib/models/adapters/postgresql_adapter.dart

import '../card/base_card.dart';
import '../card/member_card.dart';
import '../card/live_card.dart';
import '../card/energy_card.dart';
import '../card/card_factory.dart';
import '../enums/enums.dart'; // バレルファイルを使用
import '../heart.dart';
import '../blade_heart.dart';
import 'dart:convert';

class PostgreSQLAdapter {
  // PostgreSQLの生データからFlutterカードモデルに変換
  static BaseCard fromPostgreSQLRow(Map<String, dynamic> row) {
    // 基本情報の抽出
    final id = row['id'] as int;
    final cardNumber = row['card_number'] as String;
    final name = row['name'] as String;
    final rarity = row['rarity'] as String;
    final series = row['series'] as String;
    final setName = row['set_name'] as String;
    final cardType = row['card_type'] as String;
    final imageUrl = row['image_url'] as String? ?? '';
    final cardData = _safeMapConversion(row['card_data']) ?? {};
    
    // メタデータ
    final versionAdded = row['version_added'] as String? ?? '1.0.0';
    final createdAt = row['created_at'] as String?;
    final updatedAt = row['updated_at'] as String?;

    // 共通の変換処理
    final seriesEnum = _parseSeriesName(series);
    final unitEnum = _parseUnitName(cardData['unit'] as String?);

    // カードタイプ別の処理
    switch (cardType) {
      case 'member':
        return _createMemberCard(
          id: id,
          cardNumber: cardNumber,
          name: name,
          rarity: rarity,
          setName: setName,
          imageUrl: imageUrl,
          series: seriesEnum,
          unit: unitEnum,
          cardData: cardData,
          versionAdded: versionAdded,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
        
      case 'live':
        return _createLiveCard(
          id: id,
          cardNumber: cardNumber,
          name: name,
          rarity: rarity,
          setName: setName,
          imageUrl: imageUrl,
          series: seriesEnum,
          unit: unitEnum,
          cardData: cardData,
          versionAdded: versionAdded,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
        
      case 'energy':
        return _createEnergyCard(
          id: id,
          cardNumber: cardNumber,
          name: name,
          rarity: rarity,
          setName: setName,
          imageUrl: imageUrl,
          series: seriesEnum,
          unit: unitEnum,
          cardData: cardData,
          versionAdded: versionAdded,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
        
      default:
        throw Exception('Unknown card type: $cardType');
    }
  }

  // メンバーカード作成
  static MemberCard _createMemberCard({
    required int id,
    required String cardNumber,
    required String name,
    required String rarity,
    required String setName,
    required String imageUrl,
    required SeriesName series,
    required UnitName? unit,
    required Map<String, dynamic> cardData,
    required String versionAdded,
    required String? createdAt,
    required String? updatedAt,
  }) {
    // card_dataから値を抽出
    final cost = cardData['cost'] as int? ?? 0;
    final blade = cardData['blade'] as int? ?? 0;
    final effect = cardData['effect'] as String? ?? '';
    
    // ハートデータの解析
    final heartsData = _safeListConversion(cardData['hearts']) ?? [];
    final hearts = heartsData.map((heartMap) {
      final heartMapConverted = _safeMapConversion(heartMap) ?? {};
      final color = heartMapConverted['color'] as String? ?? 'any';
      return Heart(color: _parseHeartColor(color));
    }).toList();

    // ブレードハートの解析
    final bladeHeartData = _safeMapConversion(cardData['blade_heart']) ?? {};
    final bladeHearts = _parseBladeHeart(bladeHeartData);

    return MemberCard(
      id: id,
      cardCode: cardNumber,  // PostgreSQLのcard_numberをcardCodeとして使用
      rarity: rarity,
      productSet: setName,   // PostgreSQLのset_nameをproductSetとして使用
      name: name,
      series: series,
      unit: unit,
      imageUrl: imageUrl,
      cost: cost,
      hearts: hearts,
      blades: blade,        // PostgreSQLのbladeをbladesとして使用
      bladeHearts: bladeHearts,
      effect: effect,
    );
  }

  // ライブカード作成
  static LiveCard _createLiveCard({
    required int id,
    required String cardNumber,
    required String name,
    required String rarity,
    required String setName,
    required String imageUrl,
    required SeriesName series,
    required UnitName? unit,
    required Map<String, dynamic> cardData,
    required String versionAdded,
    required String? createdAt,
    required String? updatedAt,
  }) {
    final score = cardData['score'] as int? ?? 0;
    final effect = cardData['effect'] as String? ?? '';
    
    // 必要ハートの解析（ライブカード固有）
    final requiredHeartsData = _safeListConversion(cardData['required_hearts']) ?? [];
    final requiredHearts = requiredHeartsData.map((heartMap) {
      final heartMapConverted = _safeMapConversion(heartMap) ?? {};
      final color = heartMapConverted['color'] as String? ?? 'any';
      return Heart(color: _parseHeartColor(color));
    }).toList();

    // ブレードハートの解析
    final bladeHeartData = _safeMapConversion(cardData['blade_heart']) ?? {};
    final bladeHearts = _parseBladeHeart(bladeHeartData);

    return LiveCard(
      id: id,
      cardCode: cardNumber,
      rarity: rarity,
      productSet: setName,
      name: name,
      series: series,
      unit: unit,
      imageUrl: imageUrl,
      score: score,
      requiredHearts: requiredHearts,
      bladeHearts: bladeHearts,
      effect: effect,
    );
  }

  // エネルギーカード作成
  static EnergyCard _createEnergyCard({
    required int id,
    required String cardNumber,
    required String name,
    required String rarity,
    required String setName,
    required String imageUrl,
    required SeriesName series,
    required UnitName? unit,
    required Map<String, dynamic> cardData,
    required String versionAdded,
    required String? createdAt,
    required String? updatedAt,
  }) {
    return EnergyCard(
      id: id,
      cardCode: cardNumber,
      rarity: rarity,
      productSet: setName,
      name: name,
      series: series,
      unit: unit,
      imageUrl: imageUrl,
    );
  }

  // ========== ヘルパーメソッド ==========

  // 安全な型変換メソッド
  static Map<String, dynamic>? _safeMapConversion(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static List<dynamic>? _safeListConversion(dynamic data) {
    if (data == null) return null;
    if (data is List<dynamic>) return data;
    if (data is List) {
      return List<dynamic>.from(data);
    }
    return null;
  }

  // シリーズ名変換（実際のSeriesNameに対応）
  static SeriesName _parseSeriesName(String seriesStr) {
    switch (seriesStr.toLowerCase()) {
      case 'love_live': 
      case 'lovelive':
      case 'muse':
        return SeriesName.lovelive;
      case 'sunshine':
      case 'aqours': 
        return SeriesName.sunshine;
      case 'nijigasaki':
      case 'nijigaku':
        return SeriesName.nijigasaki;
      case 'superstar':
      case 'liella':
        return SeriesName.superstar;
      case 'hasunosora':
      case 'hasunosoragakuin':
        return SeriesName.hasunosoraGakuin;
      default: 
        return SeriesName.lovelive;
    }
  }

  // ユニット名変換（実際のUnitNameに対応）
  static UnitName? _parseUnitName(String? unitStr) {
    if (unitStr == null) return null;
    
    // PostgreSQL格納値（略称）から正式名称への変換
    final fullUnitName = _convertUnitCodeToFullName(unitStr);
    
    // 実際のUnitName.fromJapaneseNameメソッドを使用
    return UnitName.fromJapaneseName(fullUnitName);
  }

  // PostgreSQLの略称から正式名称への変換
  static String _convertUnitCodeToFullName(String unitCode) {
    switch (unitCode.toLowerCase()) {
      // μ'sのユニット
      case 'bibi': return 'BiBi';
      case 'lillywhite': 
      case 'lily_white': return 'lily white';
      case 'printemps': return 'Printemps';
      
      // Aqoursのユニット
      case 'guiltykiss': 
      case 'guilty_kiss': return 'Guilty Kiss';
      case 'cyaron': return 'CYaRon!';
      case 'azalea': return 'AZALEA';
      
      // 虹ヶ咲のユニット
      case 'azuna': 
      case 'a_zu_na': return 'A・ZU・NA';
      case 'diverdiva': 
      case 'diver_diva': return 'DiverDiva';
      case 'qu4rtz': return 'QU4RTZ';
      case 'r3birth': return 'R3BIRTH';
      
      // Liella!のユニット
      case 'catchu': return 'Catchu!';
      case 'kaleidoscore': return 'KALEIDOSCORE';
      case 'syncri5e': 
      case '5yncri5e': return '5yncri5e';
      case 'sunnypassion': 
      case 'sunny_passion': return 'Sunny Passion';
      
      // 蓮ノ空のユニット
      case 'cerisebouquet': 
      case 'cerise_bouquet': return 'スリーズブーケ';
      case 'dollchestra': return 'DOLLCHESTRA';
      case 'mirapa': 
      case 'miracura_park': return 'みらくらパーク!';
      case 'edelnote': 
      case 'edel_note': return 'Edel Note';
      
      // 既に正式名称の場合はそのまま返す
      default: return unitCode;
    }
  }

  // ハートカラー変換（実際のHeartColorに対応）
  static HeartColor _parseHeartColor(String colorStr) {
    switch (colorStr.toLowerCase()) {
      case 'red': return HeartColor.red;
      case 'yellow': return HeartColor.yellow;
      case 'purple': return HeartColor.purple;
      case 'pink': return HeartColor.pink;
      case 'green': return HeartColor.green;
      case 'blue': return HeartColor.blue;
      default: return HeartColor.any;
    }
  }

  // ブレードハート変換（実際のBladeHeartに対応）
  static BladeHeart _parseBladeHeart(Map<String, dynamic> bladeData) {
    if (bladeData.isEmpty) {
      return BladeHeart(quantities: {});
    }

    final Map<BladeHeartColor, int> quantities = {};
    
    // PostgreSQLのblade_heartデータ構造に応じて処理
    bladeData.forEach((key, value) {
      // キーがcolor指定の場合
      if (key == 'color' && value is String) {
        final heartColor = _parseHeartColor(value);
        final bladeHeartColor = BladeHeartColor.fromTypeAndColor(
          BladeHeartType.normal, 
          heartColor
        );
        quantities[bladeHeartColor] = 1;
      }
      
      // 数量指定の場合
      if (value is int && value > 0) {
        try {
          final bladeHeartColor = BladeHeartColor.fromJapaneseName(key);
          quantities[bladeHeartColor] = value;
        } catch (e) {
          // 解析できない場合はデフォルト値
          quantities[BladeHeartColor.normalPink] = value;
        }
      }
    });

    return BladeHeart(quantities: quantities);
  }

  // レアリティ変換（実際のRarityに対応）
  static Rarity _parseRarity(String rarityStr) {
    // RarityExtension.fromStringメソッドを使用
    return RarityExtension.fromString(rarityStr);
  }
}

// ========== 拡張されたCardFactoryクラス ==========

extension CardFactoryPostgreSQL on CardFactory {
  // PostgreSQL専用のファクトリーメソッドを追加
  static BaseCard createCardFromPostgreSQL(Map<String, dynamic> row) {
    return PostgreSQLAdapter.fromPostgreSQLRow(row);
  }
}

// ========== PostgreSQL用のカードリポジトリ ==========

class PostgreSQLCardRepository {
  // 全カード取得（PostgreSQL形式）
  static Future<List<BaseCard>> getAllCards() async {
    // TODO: 実際のAPI呼び出しまたはDB接続
    // const query = 'SELECT * FROM cards ORDER BY card_number';
    
    // 仮のAPIエンドポイント呼び出し
    throw UnimplementedError('API integration needed');
  }

  // 特定カード取得
  static Future<BaseCard?> getCardByNumber(String cardNumber) async {
    // TODO: 実装
    throw UnimplementedError('API integration needed');
  }

  // 検索機能（Enum対応）
  static Future<List<BaseCard>> searchCards({
    String? name,
    SeriesName? series,
    Rarity? rarity,
    CardType? cardType,
    UnitName? unit,
  }) async {
    // TODO: 実装
    throw UnimplementedError('API integration needed');
  }

  // レアリティフィルタリング
  static Future<List<BaseCard>> getCardsByRarity(Rarity rarity) async {
    // TODO: 実装
    throw UnimplementedError('API integration needed');
  }

  // ユニットフィルタリング
  static Future<List<BaseCard>> getCardsByUnit(UnitName unit) async {
    // TODO: 実装
    throw UnimplementedError('API integration needed');
  }

  // テスト用データ（上原歩夢のサンプル）
  static BaseCard createSampleCard() {
    final sampleData = {
      'id': 1,
      'card_number': 'PL!N-bp1-001-P',
      'name': '上原歩夢',
      'rarity': 'P',
      'series': 'love_live',
      'set_name': 'ブースターパック vol.1',
      'card_type': 'member',
      'image_url': 'https://llofficial-cardgame.com/wordpress/wp-content/images/cardlist/BP01/PL!N-bp1-001-P.png',
      'card_data': {
        "cost": 9,
        "unit": "azuna",
        "blade": 4,
        "score": 0,
        "effect": "支払ってもよい：ライブ終了時まで、を得る。",
        "hearts": [{"color": "pink"}, {"color": "pink"}, {"color": "pink"}],
        "blade_heart": {},
        "special_heart": {},
        "info_map": {
          "コスト": "9",
          "作品名": "ラブライブ！虹ヶ咲学園スクールアイドル同好会",
          "ブレード": "4",
          "収録商品": "ブースターパック vol.1",
          "カード番号": "PL!N-bp1-001-P",
          "レアリティ": "P",
          "基本ハート": "3",
          "カードタイプ": "メンバー",
          "参加ユニット": "A・ZU・NA"
        }
      },
      'version_added': '1.0.0',
      'created_at': '2025-05-18T16:44:02.894451',
      'updated_at': '2025-05-20T15:18:13.212279'
    };

    return PostgreSQLAdapter.fromPostgreSQLRow(sampleData);
  }

  // 開発用：複数サンプルカードの生成
  static List<BaseCard> createSampleCards() {
    return [
      createSampleCard(),
      // 他のサンプルカードも追加可能
    ];
  }
}

// ========== デバッグ用ヘルパー ==========

class PostgreSQLDebugHelper {
  // Enumマッピングの確認
  static void printEnumMappings() {
    print('=== Series Mapping ===');
    print('love_live -> ${_parseSeriesName('love_live')}');
    print('nijigasaki -> ${_parseSeriesName('nijigasaki')}');
    
    print('\n=== Unit Mapping ===');
    print('azuna -> ${_parseUnitName('azuna')}');
    print('qu4rtz -> ${_parseUnitName('qu4rtz')}');
    print('A・ZU・NA -> ${UnitName.fromJapaneseName('A・ZU・NA')}');
    
    print('\n=== Unit Code Conversion ===');
    print('azuna -> ${_convertUnitCodeToFullName('azuna')}');
    print('qu4rtz -> ${_convertUnitCodeToFullName('qu4rtz')}');
    
    print('\n=== Rarity Mapping ===');
    print('P -> ${RarityExtension.fromString('P')}');
    print('R -> ${RarityExtension.fromString('R')}');
    print('R+ -> ${RarityExtension.fromString('R+')}');
  }

  static SeriesName _parseSeriesName(String seriesStr) {
    return PostgreSQLAdapter._parseSeriesName(seriesStr);
  }

  static UnitName? _parseUnitName(String unitStr) {
    return PostgreSQLAdapter._parseUnitName(unitStr);
  }

  static String _convertUnitCodeToFullName(String unitCode) {
    return PostgreSQLAdapter._convertUnitCodeToFullName(unitCode);
  }
}