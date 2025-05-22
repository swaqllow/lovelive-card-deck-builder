import 'package:flutter/foundation.dart';
import '../models/card/base_card.dart';
import '../services/card_data_service.dart';

class CardDataProvider with ChangeNotifier {
  final CardDataService _cardDataService;
  
  List<BaseCard> _allCards = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _currentVersion = '0.0.0';
  DateTime? _lastSyncTime;
  String? _syncError;
  
  CardDataProvider({
    required CardDataService cardDataService,
  }) : _cardDataService = cardDataService;
  
  // ゲッター
  List<BaseCard> get allCards => _allCards;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String get currentVersion => _currentVersion;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get syncError => _syncError;
  
  // アプリ起動時の初期化
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // ローカルデータバージョンの取得
      _currentVersion = await _cardDataService.getLocalDataVersion();
      // 最終同期時間の取得
      _lastSyncTime = await _cardDataService.getLastSyncTime();
      
      // 初期カードデータのロード
      _allCards = await _cardDataService.initCardData();
      _syncError = null;
    } catch (e) {
      print('Error initializing card data: $e');
      _syncError = 'データの読み込みに失敗しました';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // データ同期の実行
  Future<bool> syncData({bool forceFullSync = false}) async {
    if (_isSyncing) return false;
    
    _isSyncing = true;
    _syncError = null;
    notifyListeners();
    
    bool success = false;
    try {
      if (forceFullSync) {
        // 強制的に完全同期を実行
        success = await _cardDataService.fullSync();
      } else {
        // 差分更新を試みる
        success = await _cardDataService.syncCardData();
        
        // 差分更新が失敗した場合は完全同期にフォールバック
        if (!success) {
          print('差分更新が失敗したため、完全同期を試みます');
          success = await _cardDataService.fullSync();
        }
      }
      
      if (success) {
        // 更新後のデータを再ロード
        _currentVersion = await _cardDataService.getLocalDataVersion();
        _lastSyncTime = await _cardDataService.getLastSyncTime();
        _allCards = await _cardDataService.initCardData();
        _syncError = null;
      } else {
        _syncError = 'データの更新に失敗しました';
      }
    } catch (e) {
      print('Error syncing card data: $e');
      _syncError = '同期中にエラーが発生しました: $e';
      success = false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
    
    return success;
  }
  
  // カードタイプ別のフィルタリング
  List<BaseCard> getCardsByType(String cardType) {
    return _allCards.where((card) => card.cardType == cardType).toList();
  }
  
  // 更新が必要かどうかチェック（UIでの表示用）
  Future<bool> checkForUpdates() async {
    return await _cardDataService.isUpdateNeeded();
  }
}