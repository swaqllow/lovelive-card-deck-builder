// lib/screens/test_scraping_screen.dart
import 'package:flutter/material.dart';
import '../services/card_scraper_service.dart';
import '../services/database_service.dart';
import '../services/database/database_helper.dart';
import '../screens/card/card_list_screen.dart';
import '../models/card/base_card.dart';
import '../models/card/member_card.dart';
import '../models/card/live_card.dart';
import '../models/enums/heart_color.dart';
import '../models/enums/unit_name.dart';
import '../models/enums/series_name.dart';

class TestScrapingScreen extends StatefulWidget {
  const TestScrapingScreen({super.key});

  @override
  _TestScrapingScreenState createState() => _TestScrapingScreenState();
}

class _TestScrapingScreenState extends State<TestScrapingScreen> {
  final CardScraperService _scraper = CardScraperService();
  final DatabaseService _db = DatabaseService();
  
  bool _isLoading = false;
  String _statusMessage = '';
  List<BaseCard> _scrapedCards = [];
  
  // 単一カードのテストスクレイピング
  Future<void> _testSingleCard() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '単一カードをテスト中...';
      _scrapedCards = [];
    });
    
    try {
      // テスト用カード番号（実際にアクセス可能なカード番号に変更）
      final cardNumber = 'PL!N-bp1-002-P';
      print('スクレイピング開始: $cardNumber');
      
      final card = await _scraper.scrapeCard(cardNumber);
      
      if (card != null) {
        setState(() {
          _scrapedCards = [card];
          _statusMessage = 'カードを取得しました: ${card.name}';
        });
        
        // デバッグ情報を出力
        print('取得したカード: ${card.toJson()}');
      } else {
        setState(() {
          _statusMessage = 'カードを取得できませんでした';
        });
      }
      if (card != null) {
      // データベースに保存
      final db = DatabaseHelper();
      await db.insertCard(card);
      
      // カード一覧画面に遷移
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CardListScreen(),
        ),
      );
    }
    child: Text('カード一覧を確認');


    } catch (e) {
      setState(() {
        _statusMessage = 'エラー: $e';
      });
      print('スクレイピングエラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 複数カードのテストスクレイピング
  Future<void> _testMultipleCards() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '複数カードをテスト中...';
      _scrapedCards = [];
    });
    
    try {
      // PL!N-bp1シリーズの1-5番のPカードを取得
      final cards = await _scraper.generateCardNumbers(
        targetSeries: ['PL!N'],
        targetPacks: ['bp1'],
        numRange: [1, 5],
        targetRarities: ['P'],
      );
      
      print('生成されたカード番号: $cards');
      
      List<BaseCard> scrapedCards = [];
      
      for (String cardNumber in cards) {
        print('スクレイピング中: $cardNumber');
        final card = await _scraper.scrapeCard(cardNumber);
        
        if (card != null) {
          scrapedCards.add(card);
          setState(() {
            _statusMessage = '処理中: ${scrapedCards.length}/${cards.length}枚 (現在: ${card.name})';
          });
        }
        
        // レート制限対策
        await Future.delayed(Duration(seconds: 2));
      }
      
      setState(() {
        _scrapedCards = scrapedCards;
        _statusMessage = '${scrapedCards.length}枚のカードを取得しました';
      });
      
    } catch (e) {
      setState(() {
        _statusMessage = 'エラー: $e';
      });
      print('複数カードスクレイピングエラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // カードをデータベースに保存
  Future<void> _saveCardsToDatabase() async {
    if (_scrapedCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存するカードがありません')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'カードをデータベースに保存中...';
    });
    
    try {
      int savedCount = 0;
      for (var card in _scrapedCards) {
        final id = await _db.saveCard(card);
        if (id > 0) savedCount++;
      }
      
      setState(() {
        _statusMessage = '$savedCount枚のカードを保存しました';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$savedCount枚のカードを保存しました')),
      );
    } catch (e) {
      setState(() {
        _statusMessage = '保存エラー: $e';
      });
      print('保存エラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // データベースからカードを読み込み
  Future<void> _loadCardsFromDatabase() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'データベースからカードを読み込み中...';
    });
    
    try {
      final cards = await _db.getAllCards();
      
      setState(() {
        _scrapedCards = cards;
        _statusMessage = '${cards.length}枚のカードを読み込みました';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '読み込みエラー: $e';
      });
      print('読み込みエラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('スクレイピングテスト'),
        backgroundColor: Color(0xFFE4007F),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // テストコントロール
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'テスト操作',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // ボタン列
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testSingleCard,
                          child: Text('単一カードテスト'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testMultipleCards,
                          child: Text('複数カードテスト'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveCardsToDatabase,
                          child: Text('DBに保存'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _loadCardsFromDatabase,
                          child: Text('DBから読み込み'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await DatabaseHelper().debugDatabase();
                          },
                          child: Text('データベース診断'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // ステータス表示
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ステータス',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    if (_isLoading)
                      LinearProgressIndicator(),
                      
                    SizedBox(height: 8),
                    Text(_statusMessage),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // 取得したカードの表示
            if (_scrapedCards.isNotEmpty) ...[
              Text(
                '取得したカード (${_scrapedCards.length}枚)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _scrapedCards.length,
                itemBuilder: (context, index) {
                  final card = _scrapedCards[index];
                  
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(card.name),
                      subtitle: Text('${card.cardCode} | ${card.cardType}'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        // カード詳細ダイアログを表示
                        _showCardDetails(card);
                      },
                    ),
                  );
                },
              ),
              ElevatedButton(
                onPressed: _scrapedCards.isNotEmpty ? _saveCardsToDatabase : null,
                child: Text('スクレイピングしたカードを保存'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // カード詳細ダイアログ
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
              Text('カード番号: ${card.cardCode}'),
              Text('レアリティ: ${card.rarity}'),
              Text('シリーズ: ${card.series.displayName}'),
              if (card.unit != null)
                Text('ユニット: ${card.unit!.displayName}'),
              
              SizedBox(height: 8),
              
              // カードタイプ別情報
              if (card is MemberCard) ...[
                Text('コスト: ${card.cost}'),
                Text('ブレード: ${card.blades}'),
                Text('ハート: ${card.hearts.map((h) => h.color.displayName).join(", ")}'),
                if (card.effect.isNotEmpty)
                  Text('効果: ${card.effect}'),
              ] else if (card is LiveCard) ...[
                Text('スコア: ${card.score}'),
                Text('必要ハート: ${card.requiredHearts.map((h) => h.color.displayName).join(", ")}'),
                if (card.effect.isNotEmpty)
                  Text('効果: ${card.effect}'),
              ],
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