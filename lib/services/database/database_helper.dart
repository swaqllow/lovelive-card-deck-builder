import 'dart:convert';
import 'dart:io';
import 'package:lovecard_deck_builder_new/models/enums/enums.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/deck.dart';
import '../../models/card/card.dart';
import '../../models/card/card_factory.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  
  factory DatabaseHelper() => _instance;
  
  DatabaseHelper._internal();
  
  // デッキを保存するディレクトリ名
  static const String _deckDirectory = 'decks';
  
  // アプリのドキュメントディレクトリ内にデッキディレクトリを取得
  Future<Directory> get _deckDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final deckDir = Directory('${appDir.path}/$_deckDirectory');
    
    // ディレクトリが存在しない場合は作成
    if (!await deckDir.exists()) {
      await deckDir.create(recursive: true);
    }
    
    return deckDir;
  }
  
  // すべてのデッキを取得
  Future<List<Deck>> getDecks() async {
    try {
      final dir = await _deckDir;
      final List<Deck> decks = [];
      
      // デッキディレクトリのすべてのファイルをリスト
      final entities = await dir.list().toList();
      
      // JSONファイルのみフィルタリング
      final deckFiles = entities.whereType<File>().where(
        (file) => file.path.endsWith('.json')
      ).toList();
      
      // 各ファイルをデッキオブジェクトに変換
      for (var file in deckFiles) {
        try {
          final jsonString = await file.readAsString();
          final jsonData = jsonDecode(jsonString);
          
          // JSONからデッキを生成
          final deck = Deck.fromJson(jsonData);
          
          // IDが設定されていない場合はファイル名から抽出
          if (deck.id == null) {
            final fileName = file.path.split('/').last;
            final idString = fileName.split('_').first;
            deck.id = int.tryParse(idString);
          }
          
          decks.add(deck);
        } catch (e) {
          print('デッキファイル読み込みエラー: ${file.path}, $e');
          // エラーがあっても処理を続行
        }
      }
      
      // 作成日時の新しい順にソート（ファイルの最終更新日を使用）
      decks.sort((a, b) {
        final fileA = File('${dir.path}/${a.id}_${a.name.replaceAll(' ', '_')}.json');
        final fileB = File('${dir.path}/${b.id}_${b.name.replaceAll(' ', '_')}.json');
        
        return fileB.lastModifiedSync().compareTo(fileA.lastModifiedSync());
      });
      
      return decks;
    } catch (e) {
      print('デッキ一覧取得エラー: $e');
      return [];
    }
  }
  
  // 新しいデッキを保存
  Future<int?> insertDeck(Deck deck) async {
    try {
      final dir = await _deckDir;
      
      // 新しいIDを生成（UTCタイムスタンプをミリ秒で）
      final id = DateTime.now().millisecondsSinceEpoch;
      deck.id = id;
      
      // デッキをJSONに変換
      final jsonData = deck.toJson();
      final jsonString = jsonEncode(jsonData);
      
      // ファイル名の作成（ID_デッキ名.json）
      final fileName = '${id}_${deck.name.replaceAll(' ', '_')}.json';
      final file = File('${dir.path}/$fileName');
      
      // ファイルに書き込み
      await file.writeAsString(jsonString);
      
      return id;
    } catch (e) {
      print('デッキ保存エラー: $e');
      return null;
    }
  }
  
  // 既存のデッキを更新
  Future<bool> updateDeck(Deck deck) async {
    try {
      if (deck.id == null) {
        return false;
      }
      
      final dir = await _deckDir;
      
      // 古いファイルの削除（ファイル名が変わる可能性があるため）
      final existingFiles = await dir.list().where(
        (entity) => entity is File && entity.path.contains('${deck.id}_')
      ).toList();
      
      for (var file in existingFiles) {
        await file.delete();
      }
      
      // 新しいファイルを作成
      final jsonData = deck.toJson();
      final jsonString = jsonEncode(jsonData);
      
      final fileName = '${deck.id}_${deck.name.replaceAll(' ', '_')}.json';
      final file = File('${dir.path}/$fileName');
      
      await file.writeAsString(jsonString);
      
      return true;
    } catch (e) {
      print('デッキ更新エラー: $e');
      return false;
    }
  }
  
  // デッキを削除
  Future<bool> deleteDeck(int id) async {
    try {
      final dir = await _deckDir;
      
      // IDに一致するファイルを探す
      final entities = await dir.list().where(
        (entity) => entity is File && entity.path.contains('${id}_')
      ).toList();
      
      if (entities.isEmpty) {
        return false;
      }
      
      // ファイルを削除
      for (var file in entities) {
        await file.delete();
      }
      
      return true;
    } catch (e) {
      print('デッキ削除エラー: $e');
      return false;
    }
  }
  
  // デッキの詳細を取得
  Future<Deck?> getDeckById(int id) async {
    try {
      final dir = await _deckDir;
      
      // IDに一致するファイルを探す
      final entities = await dir.list().where(
        (entity) => entity is File && entity.path.contains('${id}_')
      ).toList();
      
      if (entities.isEmpty) {
        return null;
      }
      
      // ファイルを読み込み
      final file = entities.first as File;
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);
      
      return Deck.fromJson(jsonData);
    } catch (e) {
      print('デッキ取得エラー: $e');
      return null;
    }
  }
  
  // デッキをJSONファイルとしてエクスポート
  Future<File?> exportDeckToFile(Deck deck, Directory destinationDir) async {
    try {
      if (deck.id == null) {
        return null;
      }
      
      final jsonData = deck.toJson();
      final jsonString = jsonEncode(jsonData);
      
      final dateStr = DateTime.now().toString().replaceAll(' ', '_').replaceAll(':', '-');
      final fileName = 'deck_${deck.name.replaceAll(' ', '_')}_$dateStr.json';
      final file = File('${destinationDir.path}/$fileName');
      
      await file.writeAsString(jsonString);
      
      return file;
    } catch (e) {
      print('デッキエクスポートエラー: $e');
      return null;
    }
  }
  
  // JSONファイルからデッキをインポート
  Future<Deck?> importDeckFromFile(File file) async {
    try {
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);
      
      // 新しいIDを生成（UTCタイムスタンプをミリ秒で）
      final id = DateTime.now().millisecondsSinceEpoch;
      
      // インポートされたデッキデータからデッキを作成
      final importedDeck = Deck.fromJson(jsonData);
      importedDeck.id = id;
      
      // インポートしたデッキを保存
      await insertDeck(importedDeck);
      
      return importedDeck;
    } catch (e) {
      print('デッキインポートエラー: $e');
      return null;
    }
  }
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'lovelive_deck_builder.db');
    return await openDatabase(
      path,
      version: 2, // バージョンアップ
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

   // データベースの作成
  Future<void> _createDB(Database db, int version) async {
    // カードテーブルの作成
    await db.execute('''
      CREATE TABLE cards(
        id INTEGER PRIMARY KEY,
        card_code TEXT NOT NULL,
        rarity TEXT NOT NULL,
        product_set TEXT NOT NULL,
        name TEXT NOT NULL,
        series TEXT NOT NULL,
        unit TEXT,
        image_url TEXT NOT NULL,
        card_type TEXT NOT NULL,
        cost INTEGER,
        data_json TEXT NOT NULL,
        version_added TEXT NOT NULL
      )
    ''');

    // デッキテーブルや他の必要なテーブルも作成
    // ...
  }
  
  // データベースのアップグレード処理
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // バージョン1→2の変更（例：version_addedカラムの追加）
      await db.execute('ALTER TABLE cards ADD COLUMN version_added TEXT DEFAULT "1.0.0"');
    }
    // 他のバージョンアップグレードロジック
  }

  // カードの挿入
  Future<int> insertCard(BaseCard card, {String? versionAdded}) async {
    Database db = await database;
    
    // カード固有のデータをJSON文字列に変換
    final cardDataJson = jsonEncode(card.toJson());
    
    // カード基本情報を含むマップを作成
    Map<String, dynamic> cardMap = {
      'id': card.id,
      'card_code': card.cardCode,
      'rarity': card.rarity,
      'product_set': card.productSet,
      'name': card.name,
      'series': card.series.toString().split('.').last,
      'unit': card.unit?.toString().split('.').last,
      'image_url': card.imageUrl,
      'card_type': card.cardType,
      'data_json': cardDataJson,
      'version_added': versionAdded ?? '1.0.0',
    };
    
    // コストフィールドの追加（メンバーカードの場合のみ）
    if (card.cardType == 'member') {
      cardMap['cost'] = (card as dynamic).cost;
    }
    
    return await db.insert('cards', cardMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 複数カードの一括挿入
  Future<void> insertCards(List<BaseCard> cards, {String? versionAdded}) async {
    Database db = await database;
    Batch batch = db.batch();
    
    for (var card in cards) {
      // カード固有のデータをJSON文字列に変換
      final cardDataJson = jsonEncode(card.toJson());
      
      // カード基本情報を含むマップを作成
      Map<String, dynamic> cardMap = {
        'id': card.id,
        'card_code': card.cardCode,
        'rarity': card.rarity,
        'product_set': card.productSet,
        'name': card.name,
        'series': card.series.toString().split('.').last,
        'unit': card.unit?.toString().split('.').last,
        'image_url': card.imageUrl,
        'card_type': card.cardType,
        'data_json': cardDataJson,
        'version_added': versionAdded ?? '1.0.0',
      };
      
      // コストフィールドの追加（メンバーカードの場合のみ）
      if (card.cardType == 'member') {
        cardMap['cost'] = (card as dynamic).cost;
      }
      
      batch.insert('cards', cardMap, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit(noResult: true);
  }

  // すべてのカードを取得
  Future<List<BaseCard>> getAllCards() async {
  final db = await database;
  
  print('=== 全カード取得開始 ===');
  
  final List<Map<String, dynamic>> maps = await db.query('cards');
  print('取得したレコード数: ${maps.length}');
  
  if (maps.isEmpty) {
    print('データベースにカードがありません');
    return [];
  }
  
  List<BaseCard> cards = [];
  for (var map in maps) {
    print('\n--- カード ${map['name']} の処理開始 ---');
    
    try {
      // data_jsonの中身を詳しく確認
      final String dataJsonStr = map['data_json'] ?? '{}';
      print('data_json文字列: $dataJsonStr');
      
      final Map<String, dynamic> dataJson = jsonDecode(dataJsonStr);
      print('data_jsonデコード結果: ${dataJson.keys.join(', ')}');
      
      // 各フィールドの存在を確認
      print('存在するフィールド:');
      print('  hearts: ${dataJson.containsKey('hearts')} (${dataJson['hearts']?.runtimeType})');
      print('  bladeHearts: ${dataJson.containsKey('bladeHearts')} (${dataJson['bladeHearts']?.runtimeType})');
      print('  effect: ${dataJson.containsKey('effect')} (${dataJson['effect']})');
      
      // カード作成処理へ
      final fullCardMap = {
        ...map,
        ...dataJson,
      };
      
      BaseCard card;
      final cardType = fullCardMap['card_type'];
      
      switch (cardType) {
        case 'member':
          print('MemberCard作成中...');
          card = MemberCard.fromMap(fullCardMap);
          break;
        case 'live':
          print('LiveCard作成中...');
          card = MemberCard.fromMap(fullCardMap);
          break;
        case 'energy':
          print('EnergyCard作成中...');
          card = MemberCard.fromMap(fullCardMap);
          break;
        default:
          print('不明なカード種別: $cardType');
          continue;
      }
      
      cards.add(card);
      print('カード作成成功: ${card.name}');
    } catch (e, stackTrace) {
      print('カード変換エラー: $e');
      print('スタックトレース: $stackTrace');
    }
  }
  
  print('\n最終的に取得したカード数: ${cards.length}');
  return cards;
}
  //   Database db = await database;
  //   List<Map<String, dynamic>> maps = await db.query('cards');
    
  //   return _convertToCards(maps);
  // }
  
  // カードタイプ別にカードを取得
  Future<List<BaseCard>> getCardsByType(String cardType) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'card_type = ?',
      whereArgs: [cardType],
    );
    
    return _convertToCards(maps);
  }
  
  // カードをIDで検索
  Future<BaseCard?> getCardById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    
    List<BaseCard> cards = _convertToCards(maps);
    return cards.first;
  }
  
  // カードの検索（名前・効果など）
  Future<List<BaseCard>> searchCards({
    String? name,
    String? series,
    String? unit,
    String? cardType,
    int? minCost,
    int? maxCost,
  }) async {
    Database db = await database;
    
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];
    
    if (name != null && name.isNotEmpty) {
      whereConditions.add('name LIKE ?');
      whereArgs.add('%$name%');
    }
    
    if (series != null) {
      whereConditions.add('series = ?');
      whereArgs.add(series);
    }
    
    if (unit != null) {
      whereConditions.add('unit = ?');
      whereArgs.add(unit);
    }
    
    if (cardType != null) {
      whereConditions.add('card_type = ?');
      whereArgs.add(cardType);
    }
    
    // コスト範囲の条件（メンバーカードにのみ適用）
    if (minCost != null && maxCost != null) {
      whereConditions.add('(card_type != "member" OR (cost >= ? AND cost <= ?))');
      whereArgs.add(minCost);
      whereArgs.add(maxCost);
    } else if (minCost != null) {
      whereConditions.add('(card_type != "member" OR cost >= ?)');
      whereArgs.add(minCost);
    } else if (maxCost != null) {
      whereConditions.add('(card_type != "member" OR cost <= ?)');
      whereArgs.add(maxCost);
    }
    
    String whereClause = whereConditions.isEmpty ? '' : whereConditions.join(' AND ');
    
    List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );
    
    return _convertToCards(maps);
  }
  
  // カードの更新
  Future<int> updateCard(BaseCard card) async {
    Database db = await database;
    
    // カード固有のデータをJSON文字列に変換
    final cardDataJson = jsonEncode(card.toJson());
    
    Map<String, dynamic> cardMap = {
      'card_code': card.cardCode,
      'rarity': card.rarity,
      'product_set': card.productSet,
      'name': card.name,
      'series': card.series.toString().split('.').last,
      'unit': card.unit?.toString().split('.').last,
      'image_url': card.imageUrl,
      'card_type': card.cardType,
      'data_json': cardDataJson,
    };
    
    // コストフィールドの更新（メンバーカードの場合のみ）
    if (card.cardType == 'member') {
      cardMap['cost'] = (card as dynamic).cost;
    }
    
    return await db.update(
      'cards',
      cardMap,
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }
  
  // カードの削除
  Future<int> deleteCardById(int id) async {
    Database db = await database;
    return await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // すべてのカードをクリア
  Future<void> clearAllCards() async {
    Database db = await database;
    await db.delete('cards');
  }
  
  // SQLクエリ結果からCardオブジェクトへの変換
  List<BaseCard> _convertToCards(List<Map<String, dynamic>> maps) {
    List<BaseCard> cards = [];
    
    for (var map in maps) {
      try {
        // data_jsonからカードデータを取得
        final cardData = jsonDecode(map['data_json']) as Map<String, dynamic>;
        // 明示的にカードタイプを設定
        cardData['card_type'] = map['card_type'];
        
        final card = CardFactory.createCardFromJson(cardData);
        cards.add(card);
      } catch (e) {
        print('Error converting card data: $e');
      }
    }
    
    return cards;
  }
  Future<void> debugCardData(String cardCode) async {
  final db = await database;
  
  print('=== カードデータ詳細解析: $cardCode ===');
  
  final List<Map<String, dynamic>> maps = await db.query(
    'cards',
    where: 'card_code = ?',
    whereArgs: [cardCode],
  );
  
  if (maps.isEmpty) {
    print('カードが見つかりません');
    return;
  }
  
  final map = maps.first;
  final dataJson = jsonDecode(map['data_json']);
  
  print('--- 生のdata_json ---');
  print('全フィールド: ${dataJson.keys.join(', ')}');
  
  // ハート関連のデータを詳しく確認
  if (dataJson.containsKey('hearts')) {
    print('\nhearts: ${dataJson['hearts']}');
    print('hearts型: ${dataJson['hearts'].runtimeType}');
    if (dataJson['hearts'] is List) {
      print('hearts内容:');
      for (var heart in dataJson['hearts']) {
        print('  - $heart (型: ${heart.runtimeType})');
      }
    }
  }
  
  // ブレードハート関連のデータを詳しく確認
  if (dataJson.containsKey('bladeHearts')) {
    print('\nbladeHearts: ${dataJson['bladeHearts']}');
    print('bladeHearts型: ${dataJson['bladeHearts'].runtimeType}');
    if (dataJson['bladeHearts'] is Map) {
      print('bladeHearts内容:');
      for (var entry in (dataJson['bladeHearts'] as Map).entries) {
        print('  - ${entry.key}: ${entry.value} (型: ${entry.value.runtimeType})');
      }
    }
  }
  
  // 効果文も確認
  if (dataJson.containsKey('effect')) {
    print('\neffect: ${dataJson['effect']}');
    print('effect文字数: ${(dataJson['effect'] as String).length}');
  }
}
}
extension CardDbQueries on DatabaseHelper {
  
  Map<String, dynamic> _convertJsonToDbMap(Map<String, dynamic> json, BaseCard card) {
    // JSONからDB形式への変換ロジック
    final dbMap = <String, dynamic>{
      'id': json['id'],
      'card_code': json['cardNo'],
      'name': json['name'],
      'rarity': json['rarity'],
      'product_set': json['productSet'],
      'series': json['series'],
      'unit': json['unit'],
      'image_url': json['imageUrl'],

      // ... 必要な変換を実装
    };
    
    // カード種別の判定
    if (card is MemberCard) {
      dbMap['card_type'] = 'member';
      dbMap['cost'] = json['cost'];
      dbMap['hearts'] = json['hearts'];
      dbMap['blades'] = json['blades'];
      dbMap['blade_hearts'] = json['bladeHearts'];
      dbMap['effect'] = json['effect'];

      // ... MemberCard固有のフィールド
    } else if (card is LiveCard) {
      dbMap['card_type'] = 'live';
      dbMap['score'] = json['score'];
      // ... LiveCard固有のフィールド
    } else if (card is EnergyCard) {
      dbMap['card_type'] = 'energy';
      // ... EnergyCard固有のフィールド
    }
    
    return dbMap;
  }
  Future<void> debugDatabase() async {
    final db = await database;
    
    print('=== データベース診断開始 ===');
    
    // カードテーブルの構造を確認
    final tableInfo = await db.rawQuery('PRAGMA table_info(cards)');
    print('テーブル構造:');
    for (var column in tableInfo) {
      print('  ${column['name']}: ${column['type']}');
    }
    
    // 保存されているカードを確認
    final allCards = await db.query('cards');
    print('\n保存済みカード (${allCards.length}件):');
    
    for (var card in allCards) {
      print('\n--- カード ${card['id']} ---');
      card.forEach((key, value) {
        print('  $key: ${value?.toString().substring(0, value.toString().length.clamp(0, 100))}');
      });
    }
  }
   Future<void> insertCard(BaseCard card) async {
    final db = await database;
    
    print('=== カード保存開始 ===');
    print('カード名: ${card.name}');
    print('カード番号: ${card.cardCode}');
    
    try {
      // スクレイピング時のデータ構造に合わせてDBマップを作成
      final dbMap = <String, dynamic>{
        'card_code': card.cardCode,
        'name': card.name,
        'rarity': card.rarity,
        'product_set': card.productSet,
        'series': card.series.displayName,
        'unit': card.unit?.name,
        'image_url': card.imageUrl,
      };
      
      // カード種別の判定と固有情報の追加
      if (card is MemberCard) {
        dbMap['card_type'] = 'member';
        dbMap['cost'] = card.cost;
        dbMap['blades'] = card.blades;
        dbMap['effect'] = card.effect;
        
        // hearts: List<Heart> → JSON文字列
        final heartList = card.hearts.map((heart) => {
          'color': heart.color.toString(),
        }).toList();
        dbMap['hearts'] = jsonEncode(heartList);
        
        // bladeHearts: BladeHeart → JSON文字列
        final bladeMap = <String, int>{};
        card.bladeHearts.quantities.forEach((key, value) {
          bladeMap[key.toString()] = value;
        });
        dbMap['blade_hearts'] = jsonEncode(bladeMap);
        
      } else if (card is LiveCard) {
        dbMap['card_type'] = 'live';
        dbMap['score'] = card.score;
        dbMap['effect'] = card.effect;
        
        // requiredHearts と bladeHearts の処理
        final heartList = card.requiredHearts.map((heart) => {
          'color': heart.color.toString(),
        }).toList();
        dbMap['required_hearts'] = jsonEncode(heartList);
        
        final bladeMap = <String, int>{};
        card.bladeHearts.quantities.forEach((key, value) {
          bladeMap[key.toString()] = value;
        });
        dbMap['blade_hearts'] = jsonEncode(bladeMap);
        
      } else if (card is EnergyCard) {
        dbMap['card_type'] = 'energy';
      }
      
      print('DBマップ: $dbMap');
      
      // 保存実行
      await db.insert(
        'cards',
        dbMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('保存成功: ${card.name}');
    } catch (e, stackTrace) {
      print('保存エラー: $e');
      print('スタックトレース: $stackTrace');
    }
  }
    Future<List<BaseCard>> getAllCards() async {
    final db = await database;
    
    print('=== 全カード取得開始 ===');
    
    final List<Map<String, dynamic>> maps = await db.query('cards');
    print('取得したレコード数: ${maps.length}');
    
    if (maps.isEmpty) {
      print('データベースにカードがありません');
      return [];
    }
    
    List<BaseCard> cards = [];
    for (var map in maps) {
      print('処理中のマップ: ${map['name']} (${map['card_code']})');
      
      try {
        // data_jsonから詳細情報を取得
        final String dataJsonStr = map['data_json'] ?? '{}';
        print('data_json: ${dataJsonStr.substring(0, dataJsonStr.length.clamp(0, 200))}...');
        
        final Map<String, dynamic> dataJson = jsonDecode(dataJsonStr);
        
        // 基本情報をmerge
        final fullCardMap = {
          'id': map['id'],
          'card_code': map['card_code'] ?? dataJson['card_code'],
          'rarity': map['rarity'] ?? dataJson['rarity'],
          'product_set': map['product_set'] ?? dataJson['product_set'],
          'name': map['name'] ?? dataJson['name'],
          'series': map['series'] ?? dataJson['series'],
          'unit': map['unit'] ?? dataJson['unit'],
          'image_url': map['image_url'] ?? dataJson['image_url'],
          'card_type': map['card_type'] ?? dataJson['card_type'],
          'cost': map['cost'] ?? dataJson['cost'],
          ...dataJson,  // data_jsonの全ての情報を追加
        };
        
        final cardType = fullCardMap['card_type'];
        print('カード種別: $cardType');
        
        BaseCard card;
        switch (cardType) {
          case 'member':
            card = MemberCard.fromMap(fullCardMap);
            break;
          case 'live':
            card = MemberCard.fromMap(fullCardMap);
            break;
          case 'energy':
            card = MemberCard.fromMap(fullCardMap);
            break;
          default:
            print('不明なカード種別: $cardType');
            continue;
        }
        
        cards.add(card);
        print('カード追加成功: ${card.name}');
      } catch (e, stackTrace) {
        print('カード変換エラー: $e');
        print('スタックトレース: $stackTrace');
      }
    }
    
    print('最終的に取得したカード数: ${cards.length}');
    return cards;
  }
}