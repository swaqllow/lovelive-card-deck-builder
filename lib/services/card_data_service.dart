import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card/card_factory.dart';
import '../models/card/base_card.dart';
import 'image_cache_service.dart';
import 'database/database_helper.dart';

class CardDataService {
  static const String serverBaseUrl = 'https://your-server.com/api';
  static const String cardDataEndpoint = '/card-data';
  
  final DatabaseHelper _dbHelper;
  final ImageCacheService _imageCacheService;
  
  CardDataService({
    required DatabaseHelper dbHelper,
    required ImageCacheService imageCacheService,
  }) : _dbHelper = dbHelper, _imageCacheService = imageCacheService;
  
  // アプリの初期化時にデータをロード
  Future<List<BaseCard>> initCardData() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
    
    List<BaseCard> cards = [];
    
    // DBからカードデータをロード
    cards = await _dbHelper.getAllCards();
    
    if (cards.isEmpty && isFirstLaunch) {
      // 初回起動時はバンドルされたデータを使用
      cards = await _loadBundledCardData();
      
      // バンドルデータをDBに保存
      if (cards.isNotEmpty) {
        await _dbHelper.insertCards(cards);
      }
      
      // 初回起動フラグを更新
      await prefs.setBool('is_first_launch', false);
    }
    
    return cards;
  }
  
  // バンドルされた基本カードデータをロード
  Future<List<BaseCard>> _loadBundledCardData() async {
    try {
      // assetsフォルダからJSONファイルを読み込み
      final memberCardsJson = await rootBundle.loadString('assets/data/member_cards_base.json');
      final liveCardsJson = await rootBundle.loadString('assets/data/live_cards_base.json');
      final energyCardsJson = await rootBundle.loadString('assets/data/energy_cards_base.json');
      
      List<BaseCard> allCards = [];
      
      // メンバーカードの変換
      final memberCardsList = jsonDecode(memberCardsJson) as List;
      for (final cardJson in memberCardsList) {
        cardJson['card_type'] = 'member';
        final card = CardFactory.createCardFromJson(cardJson);
        allCards.add(card);
      }
      
      // ライブカードの変換
      final liveCardsList = jsonDecode(liveCardsJson) as List;
      for (final cardJson in liveCardsList) {
        cardJson['card_type'] = 'live';
        final card = CardFactory.createCardFromJson(cardJson);
        allCards.add(card);
      }
      
      // エネルギーカードの変換
      final energyCardsList = jsonDecode(energyCardsJson) as List;
      for (final cardJson in energyCardsList) {
        cardJson['card_type'] = 'energy';
        final card = CardFactory.createCardFromJson(cardJson);
        allCards.add(card);
      }
      
      return allCards;
    } catch (e) {
      print('Error loading bundled card data: $e');
      return [];
    }
  }
  
  // バージョン情報とメタデータの取得
  Future<Map<String, dynamic>?> getCardDataMetadata() async {
    try {
      final response = await http.get(
        Uri.parse('$serverBaseUrl$cardDataEndpoint/metadata')
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting card data metadata: $e');
      return null;
    }
  }
  
  // ローカルのデータバージョンを取得
  Future<String> getLocalDataVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('card_data_version') ?? '0';
  }
  
  // サーバーとローカルのバージョンを比較して更新が必要か判断
  Future<bool> isUpdateNeeded() async {
    final metadata = await getCardDataMetadata();
    if (metadata == null) return false;
    
    final serverVersion = metadata['version'] as String;
    final localVersion = await getLocalDataVersion();
    
    // バージョン文字列を数値に変換して比較
    final serverVersionNum = int.parse(serverVersion.replaceAll('.', ''));
    final localVersionNum = int.parse(localVersion.replaceAll('.', ''));
    
    return serverVersionNum > localVersionNum;
  }
  
  // カードデータの差分更新（増分更新）
  Future<bool> syncCardData() async {
    try {
      // 更新が必要か確認
      if (!await isUpdateNeeded()) {
        print('カードデータは最新です');
        return true;
      }
      
      final localVersion = await getLocalDataVersion();
      
      // 差分更新APIを呼び出し
      final response = await http.get(
        Uri.parse('$serverBaseUrl$cardDataEndpoint/diff?from_version=$localVersion')
      );
      
      if (response.statusCode != 200) {
        return false;
      }
      
      final updateData = jsonDecode(response.body);
      
      // 更新されたカードデータを処理
      await _processCardUpdates(updateData);
      
      // バージョン情報を更新
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('card_data_version', updateData['version']);
      await prefs.setString('last_card_sync_time', DateTime.now().toIso8601String());
      
      return true;
    } catch (e) {
      print('Error syncing card data: $e');
      return false;
    }
  }
  
  // 更新データを処理
  Future<void> _processCardUpdates(Map<String, dynamic> updateData) async {
    final addedCards = updateData['added_cards'] as List?;
    final updatedCards = updateData['updated_cards'] as List?;
    final deletedCardIds = updateData['deleted_card_ids'] as List?;
    
    // 削除されたカードの処理
    if (deletedCardIds != null && deletedCardIds.isNotEmpty) {
      for (final id in deletedCardIds) {
        await _dbHelper.deleteCardById(id);
      }
    }
    
    // 追加されたカードの処理
    if (addedCards != null && addedCards.isNotEmpty) {
      final List<BaseCard> newCards = [];
      
      for (final cardJson in addedCards) {
        final cardType = cardJson['card_type'] as String? ?? 'member';
        cardJson['card_type'] = cardType;
        
        final card = CardFactory.createCardFromJson(cardJson);
        newCards.add(card);
        
        // カード画像のプリロード処理
        if (cardJson['image_url'] != null && cardJson['image_url'].isNotEmpty) {
          _imageCacheService.cacheImage(cardJson['image_url']);
        }
      }
      
      if (newCards.isNotEmpty) {
        await _dbHelper.insertCards(newCards);
      }
    }
    
    // 更新されたカードの処理
    if (updatedCards != null && updatedCards.isNotEmpty) {
      for (final cardJson in updatedCards) {
        final cardType = cardJson['card_type'] as String? ?? 'member';
        cardJson['card_type'] = cardType;
        
        final card = CardFactory.createCardFromJson(cardJson);
        await _dbHelper.updateCard(card);
        
        // カード画像の更新処理
        if (cardJson['image_url'] != null && cardJson['image_url'].isNotEmpty) {
          _imageCacheService.cacheImage(cardJson['image_url'], forceUpdate: true);
        }
      }
    }
  }
  
  // 最終同期日時を取得
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncTimeStr = prefs.getString('last_card_sync_time');
    if (lastSyncTimeStr != null) {
      return DateTime.parse(lastSyncTimeStr);
    }
    return null;
  }
  
  // 全更新（フォールバック用）
  Future<bool> fullSync() async {
    try {
      // 全カードデータの取得
      final response = await http.get(
        Uri.parse('$serverBaseUrl$cardDataEndpoint/all')
      );
      
      if (response.statusCode != 200) {
        return false;
      }
      
      final fullData = jsonDecode(response.body);
      
      // DBをクリア
      await _dbHelper.clearAllCards();
      
      // メタデータの更新
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('card_data_version', fullData['version']);
      await prefs.setString('last_card_sync_time', DateTime.now().toIso8601String());
      
      // すべてのカードを挿入
      final allCards = fullData['cards'] as List;
      final List<BaseCard> cardObjects = [];
      
      for (final cardJson in allCards) {
        final cardType = cardJson['card_type'] as String? ?? 'member';
        cardJson['card_type'] = cardType;
        
        final card = CardFactory.createCardFromJson(cardJson);
        cardObjects.add(card);
      }
      
      await _dbHelper.insertCards(cardObjects);
      
      return true;
    } catch (e) {
      print('Error during full sync: $e');
      return false;
    }
  }
}