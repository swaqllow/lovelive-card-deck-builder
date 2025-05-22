import 'package:flutter/material.dart';
import '../../models/deck.dart';
import '../../models/card/base_card.dart';
import '../../models/card/member_card.dart';
import '../../models/card/live_card.dart';
import 'deck_metadata_screen.dart';
import 'deck_recipe_edit_screen.dart';
import 'deck_report_screen.dart';

class DeckViewScreen extends StatelessWidget {
  final Deck deck;
  
  const DeckViewScreen({super.key, required this.deck});
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(deck.name),
          backgroundColor: Color(0xFFE4007F), // ラブライブピンク
          actions: [
            // メタデータ編集ボタン
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeckMetadataScreen(
                      isNewDeck: false,
                      deck: deck,
                    ),
                  ),
                );
              },
              tooltip: 'デッキ情報を編集',
            ),
            // レポート表示ボタン
            IconButton(
              icon: Icon(Icons.bar_chart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeckReportScreen(deck: deck),
                  ),
                );
              },
              tooltip: 'デッキレポートを表示',
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'メインデッキ'),
              Tab(text: 'エネルギーデッキ'),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: Column(
          children: [
            // デッキ情報表示部分
            _buildDeckInfoSection(),
            
            // タブビュー
            Expanded(
              child: TabBarView(
                children: [
                  // メインデッキタブ
                  _buildDeckCardsGrid(deck.mainDeckCards),
                  
                  // エネルギーデッキタブ
                  _buildDeckCardsGrid(deck.energyDeckCards),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeckRecipeEditScreen(deck: deck),
              ),
            );
          },
          backgroundColor: Color(0xFFE4007F),
          tooltip: 'デッキを編集', // ラブライブピンク
          child: Icon(Icons.edit),
        ),
      ),
    );
  }
  
  Widget _buildDeckInfoSection() {
    final totalCards = deck.mainDeckSize + deck.energyDeckSize;
    final memberCardCount = deck.memberCardCount;
    final liveCardCount = deck.liveCardCount;
    final isValid = deck.isValid();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'デッキ情報',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          
          // カード枚数情報
          Row(
            children: [
              _buildInfoItem(
                'メインデッキ',
                '${deck.mainDeckSize}枚',
                icon: Icons.style,
              ),
              Container(
                height: 36,
                width: 1,
                color: Colors.grey[300],
                margin: EdgeInsets.symmetric(horizontal: 12),
              ),
              _buildInfoItem(
                'エネルギーデッキ',
                '${deck.energyDeckSize}枚',
                icon: Icons.bolt,
              ),
              Container(
                height: 36,
                width: 1,
                color: Colors.grey[300],
                margin: EdgeInsets.symmetric(horizontal: 12),
              ),
              _buildInfoItem(
                '合計',
                '$totalCards枚',
                icon: Icons.content_paste,
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // 詳細情報
          Row(
            children: [
              _buildInfoItem(
                'メンバーカード',
                '$memberCardCount枚',
                icon: Icons.person,
              ),
              Container(
                height: 36,
                width: 1,
                color: Colors.grey[300],
                margin: EdgeInsets.symmetric(horizontal: 12),
              ),
              _buildInfoItem(
                'ライブカード',
                '$liveCardCount枚',
                icon: Icons.music_note,
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // 有効性表示
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isValid 
                  ? Colors.green.withOpacity(0.1) 
                  : Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isValid ? Colors.green : Colors.amber,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.warning,
                  color: isValid ? Colors.green : Colors.amber,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  isValid 
                      ? 'デッキは有効です'
                      : 'デッキ構成が無効です（メイン：メンバー48枚、ライブ12枚、エネルギー：12枚が必要）',
                  style: TextStyle(
                    color: isValid ? Colors.green[700] : Colors.amber[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // メモの表示（もしあれば）
          if (deck.notes.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'メモ:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(deck.notes),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          SizedBox(width: 4),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDeckCardsGrid(List<dynamic> cards) {
    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'カードがありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              '編集ボタンからカードを追加しましょう',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _buildCardItem(card);
      },
    );
  }
  
  Widget _buildCardItem(BaseCard card) {
    // カードタイプに応じた背景色を設定
    Color cardTypeColor;
    IconData cardTypeIcon;
    
    if (card is MemberCard) {
      cardTypeColor = Colors.purple.withOpacity(0.7);
      cardTypeIcon = Icons.person;
    } else if (card is LiveCard) {
      cardTypeColor = Colors.blue.withOpacity(0.7);
      cardTypeIcon = Icons.music_note;
    } else {
      // エネルギーカード
      cardTypeColor = Colors.amber.withOpacity(0.7);
      cardTypeIcon = Icons.bolt;
    }
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          // カード詳細表示（モーダルなど）
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // カードタイプインジケーター
            Container(
              color: cardTypeColor,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cardTypeIcon,
                    color: Colors.white,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    card.rarity,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // カード画像
            Expanded(
              child: card.imageUrl.isNotEmpty
                  ? Image.network(
                      card.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 32,
                              color: Colors.grey[500],
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(
                          Icons.image,
                          size: 32,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
            ),
            
            // カード情報
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    card.series.toString().split('.').last,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}