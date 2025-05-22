// lib/screens/database_test_screen.dart
import 'package:flutter/material.dart';
import '../services/database/database_helper.dart';
import '../models/card/base_card.dart';

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  _DatabaseTestScreenState createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  String _diagnosticInfo = '';
  List<BaseCard> _cards = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }
  
  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _diagnosticInfo = 'データベース診断中...\n\n';
    });
    
      try {
        // 1. データベース初期化確認
        try {
          final db = await _db.database;
          _addInfo('✓ データベース初期化: 成功');
          _addInfo('データベースパス: ${db.path}');
          
          // SQLiteのPRAGMA文でバージョンを取得
          final versionResult = await db.rawQuery('PRAGMA user_version');
          String version = 'unknown';
          
          if (versionResult.isNotEmpty && versionResult.first['user_version'] != null) {
            version = versionResult.first['user_version'].toString();
          }
          
          _addInfo('データベースバージョン: $version');
          
        } catch (e) {
          _addInfo('✗ データベース初期化: 失敗 ($e)');
          return;
        }
          
      // 2. テーブル存在確認
      final tables = await _db.database.then((db) => db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      ));
      
      _addInfo('\nテーブル一覧:');
      for (var table in tables) {
        _addInfo('  - ${table['name']}');
      }
      
      // 3. カード数の確認
      final cardCount = await _db.database.then((db) => db.rawQuery(
        "SELECT COUNT(*) as count FROM cards"
      ));
      
      _addInfo('\nカード数: ${cardCount.first['count']}');
      
      // 4. カードタイプ別の統計
      final cardTypes = await _db.database.then((db) => db.rawQuery(
        "SELECT card_type, COUNT(*) as count FROM cards GROUP BY card_type"
      ));
      
      _addInfo('\nカードタイプ別統計:');
      for (var type in cardTypes) {
        _addInfo('  - ${type['card_type']}: ${type['count']}枚');
      }
      
      // 5. 実際のカードデータを読み込み
      final cards = await _db.getAllCards();
      setState(() {
        _cards = cards;
      });
      
      _addInfo('\n実際のカード例:');
      if (cards.isNotEmpty) {
        final card = cards.first;
        _addInfo('  - ${card.name} (${card.cardCode})');
        _addInfo('    タイプ: ${card.cardType}');
      } else {
        _addInfo('  カードが存在しません');
      }
      
    } catch (e, stackTrace) {
      _addInfo('\n診断エラー: $e');
      _addInfo('スタックトレース: $stackTrace');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _addInfo(String message) {
    setState(() {
      _diagnosticInfo += '$message\n';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('データベース診断'),
        backgroundColor: Color(0xFFE4007F),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _runDiagnostics,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 診断情報
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _diagnosticInfo,
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ),
            
            SizedBox(height: 16),
            
            // カード一覧
            if (_cards.isNotEmpty) ...[
              Text(
                'カード一覧 (${_cards.length}枚)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _cards.length > 10 ? 10 : _cards.length,
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  return ListTile(
                    title: Text(card.name),
                    subtitle: Text('${card.cardCode} | ${card.cardType}'),
                    trailing: Icon(Icons.info_outline),
                    onTap: () {
                      _showCardDetails(card);
                    },
                  );
                },
              ),
              
              if (_cards.length > 10)
                Center(
                  child: Text(
                    '...他${_cards.length - 10}枚',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showCardDetails(BaseCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(card.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('データ構造:'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  card.toJson().toString(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('閉じる'),
          ),
        ],
      ),
    );
  }
}