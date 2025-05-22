import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/card_data_provider.dart';
import '../services/image_cache_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showAdvancedOptions = false;
  int _cacheSize = 0;
  
  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }
  
  Future<void> _loadCacheSize() async {
    final imageCacheService = Provider.of<ImageCacheService>(context, listen: false);
    final sizeInBytes = await imageCacheService.getCacheSize();
    
    setState(() {
      _cacheSize = sizeInBytes;
    });
  }
  
  // ファイルサイズを人間が読みやすい形式に変換
  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  // 更新確認ダイアログを表示
  Future<void> _showUpdateDialog(BuildContext context, bool updateAvailable) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(updateAvailable ? '更新があります' : '最新の状態です'),
          content: Text(
            updateAvailable 
              ? 'カードデータに更新があります。ダウンロードしますか？'
              : 'カードデータは既に最新の状態です。'
          ),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (updateAvailable)
              TextButton(
                child: Text('更新'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _syncCardData(false);
                },
              ),
          ],
        );
      },
    );
  }
  
  // カードデータの同期を実行
  Future<void> _syncCardData(bool forceFullSync) async {
    final cardDataProvider = Provider.of<CardDataProvider>(context, listen: false);
    
    if (!forceFullSync) {
      // 更新があるか確認
      final updateAvailable = await cardDataProvider.checkForUpdates();
      
      if (!updateAvailable) {
        await _showUpdateDialog(context, false);
        return;
      }
      
      await _showUpdateDialog(context, true);
    }
    
    // プログレスダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(forceFullSync ? '完全更新を実行中...' : 'カードデータを更新中...'),
            ],
          ),
        );
      },
    );
    
    // 同期実行
    final success = await cardDataProvider.syncData(forceFullSync: forceFullSync);
    
    // プログレスダイアログを閉じる
    Navigator.of(context).pop();
    
    // 結果表示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success 
            ? 'カードデータを最新の状態に更新しました' 
            : 'カードデータの更新に失敗しました: ${cardDataProvider.syncError}'
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    
    // キャッシュサイズを再計算
    await _loadCacheSize();
  }
  
  @override
  Widget build(BuildContext context) {
    final cardDataProvider = Provider.of<CardDataProvider>(context);
    final imageCacheService = Provider.of<ImageCacheService>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('設定'),
        backgroundColor: Color(0xFFE4007F), // ラブライブピンク
      ),
      body: ListView(
        children: [
          // カードデータ更新セクション
          Card(
            margin: EdgeInsets.all(8),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'カードデータ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  ListTile(
                    title: Text('カードデータを更新'),
                    subtitle: Text(
                      cardDataProvider.lastSyncTime != null
                          ? '最終更新: ${_formatDateTime(cardDataProvider.lastSyncTime!)} (v${cardDataProvider.currentVersion})'
                          : '未更新',
                    ),
                    trailing: cardDataProvider.isSyncing
                        ? CircularProgressIndicator()
                        : Icon(Icons.refresh),
                    onTap: cardDataProvider.isSyncing 
                        ? null 
                        : () => _syncCardData(false),
                  ),
                ],
              ),
            ),
          ),
          
          // イメージキャッシュセクション
          Card(
            margin: EdgeInsets.all(8),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'キャッシュ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  ListTile(
                    title: Text('画像キャッシュ'),
                    subtitle: Text('現在のサイズ: ${_formatFileSize(_cacheSize)}'),
                    trailing: Icon(Icons.delete_outline),
                    onTap: () async {
                      await imageCacheService.clearAllCache();
                      await _loadCacheSize();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('画像キャッシュをクリアしました')),
                      );
                    },
                  ),
                  ListTile(
                    title: Text('古いキャッシュを整理'),
                    subtitle: Text('30日以上アクセスされていない画像を削除'),
                    trailing: Icon(Icons.cleaning_services_outlined),
                    onTap: () async {
                      await imageCacheService.clearOldCache();
                      await _loadCacheSize();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('古いキャッシュを整理しました')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // 詳細設定セクション
          Card(
            margin: EdgeInsets.all(8),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showAdvancedOptions = !_showAdvancedOptions;
                      });
                    },
                    child: Row(
                      children: [
                        Text(
                          '詳細設定',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Icon(
                          _showAdvancedOptions
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                      ],
                    ),
                  ),
                  if (_showAdvancedOptions) ...[
                    SizedBox(height: 8),
                    ListTile(
                      title: Text('データを完全更新'),
                      subtitle: Text('すべてのカードデータを再ダウンロードします'),
                      trailing: Icon(Icons.sync),
                      onTap: cardDataProvider.isSyncing
                          ? null
                          : () => _syncCardData(true),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // バージョン情報
          Card(
            margin: EdgeInsets.all(8),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'アプリ情報',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  ListTile(
                    title: Text('バージョン'),
                    subtitle: Text('v1.0.0'),
                  ),
                  ListTile(
                    title: Text('カードデータバージョン'),
                    subtitle: Text('v${cardDataProvider.currentVersion}'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}