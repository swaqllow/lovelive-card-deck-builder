// lib/screens/card_list_screen.dart
import 'package:flutter/material.dart';
import '../../models/card/base_card.dart';
import '../../models/card/member_card.dart';
import '../../services/database/database_helper.dart';
import '../../screens/card/card_detail_screen.dart';
import 'dart:io';


class CardListScreen extends StatefulWidget {
  const CardListScreen({super.key});

  @override
  _CardListScreenState createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  List<BaseCard> cards = [];
  bool isLoading = true;
  String searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadCards();
  }
  
  // lib/screens/card_list_screen.dart
  Future<void> _loadCards() async {
    try {
      print('=== カード読み込み開始 ===');
      final db = DatabaseHelper();
      

      // ここに診断を追加
      await db.debugDatabase();
      final loadedCards = await db.getAllCards();

      print('DBから取得したカード数: ${loadedCards.length}');
      
      // 各カードの情報を確認
      for (var card in loadedCards) {
        print('カード: ${card.name} / ${card.cardCode} / 種別: ${card.runtimeType}');
        if (card is MemberCard) {
        print('  - コスト: ${card.cost}');
        print('  - ブレード: ${card.blades}');
        print('  - ハート数: ${card.hearts.length}');
      }

      }
      
      setState(() {
        cards = loadedCards;
        isLoading = false;
      });
      
      print('カード読み込み成功: ${cards.length}枚');
    } catch (e, stackTrace) {
      print('カード読み込みエラー: $e');
      print('スタックトレース: $stackTrace');
      setState(() {
        isLoading = false;
      });
    }
  }
  
  List<BaseCard> get filteredCards {
    if (searchQuery.isEmpty) return cards;
    
    return cards.where((card) {
      return card.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
             card.cardCode.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    print('=== CardListScreen build実行 ===');
    print('isLoading: $isLoading');
    print('cards.length: ${cards.length}');
    print('filteredCards.length: ${filteredCards.length}');
    return Scaffold(
      appBar: AppBar(
        title: Text('カード一覧 (${filteredCards.length}/${cards.length})'),
      ),
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'カード検索',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          
          // カード一覧
          if (isLoading)
            Expanded(child: Center(child: CircularProgressIndicator()))
          else if (filteredCards.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  cards.isEmpty 
                    ? 'カードが登録されていません' 
                    : '検索条件に一致するカードがありません'
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: filteredCards.length,
                itemBuilder: (context, index) {
                  return _buildCardItem(filteredCards[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildCardItem(BaseCard card) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CardDetailScreen(card: card),
          ),
        );
      },
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // カード画像
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: card.imageUrl.isNotEmpty
                    ? Image.file(
                        File(card.imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image_not_supported);
                        },
                      )
                    : Icon(Icons.image, size: 50),
              ),
            ),
            
            // カード情報
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${card.cardCode} | ${card.rarity}',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  void testCardData() async {
  final db = DatabaseHelper();
  
  // 実際のカードコードでデバッグ
  await db.debugCardData('PL!N-bp1-002-P');
  
  // カード取得のテスト
  final card = await db.getCardById(0);
  
  if (card != null && card is MemberCard) {
    print('\n=== カード情報確認 ===');
    print('名前: ${card.name}');
    print('ハート数: ${card.hearts.length}');
    print('ハート詳細:');
    for (var heart in card.hearts) {
      print('  - ${heart.color}');
    }
    print('ブレードハート: ${card.bladeHearts.quantities}');
    print('効果: ${card.effect}');
  }
}
}