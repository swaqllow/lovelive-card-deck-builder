import 'package:lovecard_deck_builder_new/models/enums/series_name.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/card/base_card.dart';
import '../models/card/member_card.dart';
import '../models/heart.dart';
import '../models/blade_heart.dart';
import '../models/enums/heart_color.dart';
import '../models/enums/blade_heart.dart';
import '../models/enums/unit_name.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  
  factory DatabaseService() => _instance;
  
  DatabaseService._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'lovelive_card_game.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }
  
  Future<void> _createDB(Database db, int version) async {
    // カードテーブル
    await db.execute('''
      CREATE TABLE cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_code TEXT NOT NULL,
        name TEXT NOT NULL,
        rarity TEXT NOT NULL,
        product_set TEXT NOT NULL,
        series TEXT NOT NULL,
        unit TEXT,
        image_url TEXT,
        card_type TEXT NOT NULL,
        cost INTEGER,
        blades INTEGER,
        effect TEXT
      )
    ''');
    
    // ハートテーブル
    await db.execute('''
      CREATE TABLE hearts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id INTEGER,
        color TEXT NOT NULL,
        FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
      )
    ''');
    
    // ブレードハートテーブル
    await db.execute('''
      CREATE TABLE blade_hearts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id INTEGER,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
      )
    ''');
  }
  
  // カードの保存
  Future<int> saveCard(BaseCard card) async {
    final db = await database;
    final batch = db.batch();
    
    // カード基本情報
    final cardMap = {
      'card_code': card.cardCode,
      'name': card.name,
      'rarity': card.rarity,
      'product_set': card.productSet,
      'series': card.series.toString().split('.').last,
      'unit': card.unit?.toString().split('.').last,
      'image_url': card.imageUrl,
      'card_type': card.cardType,
    };
    
    // カードタイプ別の追加情報
    if (card is MemberCard) {
      cardMap['cost'] = card.cost.toString();
      cardMap['blades'] = card.blades.toString();
      cardMap['effect'] = card.effect;
    }
    
    // カード情報を挿入
    final cardId = await db.insert('cards', cardMap);
    
    // ハート情報の挿入
    if (card is MemberCard) {
      for (var heart in card.hearts) {
        await db.insert('hearts', {
          'card_id': cardId,
          'color': heart.color.toString().split('.').last,
        });
      }
      
      // ブレードハート情報の挿入
      for (var entry in card.bladeHearts.quantities.entries) {
        if (entry.value > 0) {
          await db.insert('blade_hearts', {
            'card_id': cardId,
            'type': entry.key.toString().split('.').last,
            'quantity': entry.value,
          });
        }
      }
    }
    
    return cardId;
  }
  
  // カードの一括保存
  Future<void> saveBulkCards(List<BaseCard> cards) async {
    final db = await database;
    
    await db.transaction((txn) async {
      for (var card in cards) {
        // カード基本情報
        final cardMap = {
          'card_code': card.cardCode,
          'name': card.name,
          'rarity': card.rarity,
          'product_set': card.productSet,
          'series': card.series.toString().split('.').last,
          'unit': card.unit?.toString().split('.').last,
          'image_url': card.imageUrl,
          'card_type': card.cardType,
        };
        
        // カードタイプ別の追加情報
        if (card is MemberCard) {
          cardMap['cost'] = card.cost.toString();
          cardMap['blades'] = card.blades.toString();
          cardMap['effect'] = card.effect;
        }
        
        // カード情報を挿入
        final cardId = await txn.insert('cards', cardMap);
        
        // ハート情報の挿入
        if (card is MemberCard) {
          for (var heart in card.hearts) {
            await txn.insert('hearts', {
              'card_id': cardId,
              'color': heart.color.toString().split('.').last,
            });
          }
          
          // ブレードハート情報の挿入
          for (var entry in card.bladeHearts.quantities.entries) {
            if (entry.value > 0) {
              await txn.insert('blade_hearts', {
                'card_id': cardId,
                'type': entry.key.toString().split('.').last,
                'quantity': entry.value,
              });
            }
          }
        }
      }
    });
  }
  
  // カードの取得（関連データも含めて）
  Future<List<BaseCard>> getAllCards() async {
    final db = await database;
    final cardMaps = await db.query('cards');
    
    List<BaseCard> cards = [];
    
    for (var cardMap in cardMaps) {
      final cardId = cardMap['id'] as int;
      final cardType = cardMap['card_type'] as String;
      
      if (cardType == 'member') {
        // ハート情報の取得
        final heartMaps = await db.query(
          'hearts',
          where: 'card_id = ?',
          whereArgs: [cardId],
        );
        
        List<Heart> hearts = heartMaps.map((map) {
          final colorStr = map['color'] as String;
          final heartColor = HeartColor.values.firstWhere(
            (c) => c.toString().split('.').last == colorStr,
            orElse: () => HeartColor.any,
          );
          return Heart(color: heartColor);
        }).toList();
        
        // ブレードハート情報の取得
        final bladeHeartMaps = await db.query(
          'blade_hearts',
          where: 'card_id = ?',
          whereArgs: [cardId],
        );
        
        Map<BladeHeartColor, int> bladeHeartQuantities = {};
        for (var map in bladeHeartMaps) {
          final typeStr = map['type'] as String;
          final quantity = map['quantity'] as int;
          
          final type = BladeHeartColor.values.firstWhere(
            (t) => t.toString().split('.').last == typeStr,
            orElse: () => BladeHeartColor.normalPink,
          );
          
          bladeHeartQuantities[type] = quantity;
        }
        
        // シリーズとユニットの変換
        final seriesStr = cardMap['series'] as String;
        final series = SeriesName.fromJapaneseName(seriesStr);
        
        
        UnitName? unit;
        if (cardMap['unit'] != null) {
          final unitStr = cardMap['unit'] as String;
          unit = UnitName.values.firstWhere(
            (u) => u.toString().split('.').last == unitStr,
            orElse: () => UnitName.bibi,
          );
        }
        
        // メンバーカードの作成
        cards.add(
          MemberCard(
            id: cardId,
            cardCode: cardMap['card_code'] as String,
            name: cardMap['name'] as String,
            rarity: cardMap['rarity'] as String,
            productSet: cardMap['product_set'] as String,
            series: series,
            unit: unit,
            imageUrl: cardMap['image_url'] as String? ?? '',
            cost: cardMap['cost'] as int? ?? 0,
            hearts: hearts,
            blades: cardMap['blades'] as int? ?? 0,
            bladeHearts: BladeHeart(quantities: bladeHeartQuantities),
            effect: cardMap['effect'] as String? ?? '',
          ),
        );
      }
      
      // ライブカード、エネルギーカードも同様に実装
    }
    
    return cards;
  }
}