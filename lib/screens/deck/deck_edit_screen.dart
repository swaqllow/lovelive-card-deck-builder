import 'package:flutter/material.dart';
import '../../models/deck.dart';
import '../../models/card/base_card.dart';
import '../../models/card/member_card.dart';
import '../../models/card/live_card.dart';
import '../../models/card/energy_card.dart';
import '../../services/database/database_helper.dart';
import '../card/card_search_screen.dart';

class DeckEditScreen extends StatefulWidget {
  final Deck deck;
  
  const DeckEditScreen({super.key, required this.deck});
  
  @override
  _DeckEditScreenState createState() => _DeckEditScreenState();
}

class _DeckEditScreenState extends State<DeckEditScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<BaseCard> _mainDeckCards;
  late List<EnergyCard> _energyDeckCards;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isDirty = false;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _mainDeckCards = List.from(widget.deck.mainDeckCards);
    _energyDeckCards = List.from(widget.deck.energyDeckCards);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // メインデッキのメンバーカード数を取得
  int get _memberCardCount => _mainDeckCards.whereType<MemberCard>().length;
  
  // メインデッキのライブカード数を取得
  int get _liveCardCount => _mainDeckCards.whereType<LiveCard>().length;
  
  // 現在のデッキが有効かどうかチェック
  bool get _isValidDeck {
    final validMainDeckSize = _mainDeckCards.length == 60;
    final validMemberCount = _memberCardCount == 48;
    final validLiveCount = _liveCardCount == 12;
    final validEnergyDeckSize = _energyDeckCards.length == 12;
    
    return validMainDeckSize && validMemberCount && validLiveCount && validEnergyDeckSize;
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('デッキ編集'),
          backgroundColor: Color(0xFFE4007F), // ラブライブピンク
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'メインデッキ'),
              Tab(text: 'エネルギーデッキ'),
            ],
          ),
          actions: [
            // 保存ボタン
            _isSaving
                ? Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.save),
                    onPressed: _isDirty ? _saveDeck : null,
                    tooltip: 'デッキを保存',
                  ),
          ],
        ),
        body: Column(
          children: [
            // デッキステータス情報
            _buildDeckStatusBar(),
            
            // メイン・エネルギーデッキ切り替えタブビュー
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // メインデッキタブ
                  _buildMainDeckTab(),
                  
                  // エネルギーデッキタブ
                  _buildEnergyDeckTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Color(0xFFE4007F),
          onPressed: _addCards,
          tooltip: 'カードを追加',
          child: Icon(Icons.add),
        ),
      ),
    );
  }
  
  // デッキステータスバー
  Widget _buildDeckStatusBar() {
    return Container(
      padding: EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Row(
        children: [
          // メインデッキ情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'メインデッキ: ${_mainDeckCards.length}/60枚',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'メンバー: $_memberCardCount/48枚 • ライブ: $_liveCardCount/12枚',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          
          // エネルギーデッキ情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'エネルギーデッキ: ${_energyDeckCards.length}/12枚',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '必要枚数: 12枚',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          
          // デッキ有効性アイコン
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _isValidDeck ? Colors.green[100] : Colors.amber[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  _isValidDeck ? Icons.check_circle : Icons.warning,
                  color: _isValidDeck ? Colors.green : Colors.amber,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  _isValidDeck ? '有効' : '無効',
                  style: TextStyle(
                    color: _isValidDeck ? Colors.green : Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // メインデッキタブの内容
  Widget _buildMainDeckTab() {
    return Column(
      children: [
        // フィルターコントロール
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  label: 'すべて',
                  count: _mainDeckCards.length,
                  isSelected: true,
                  onSelected: (selected) {},
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  label: 'メンバー',
                  count: _memberCardCount,
                  isSelected: false,
                  onSelected: (selected) {},
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  label: 'ライブ',
                  count: _liveCardCount,
                  isSelected: false,
                  onSelected: (selected) {},
                ),
              ),
            ],
          ),
        ),
        
        // カード一覧
        Expanded(
          child: _mainDeckCards.isEmpty
              ? _buildEmptyState('メインデッキにカードがありません', true)
              : GridView.builder(
                  padding: EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _mainDeckCards.length,
                  itemBuilder: (context, index) {
                    return _buildCardItem(
                      _mainDeckCards[index],
                      onRemove: () => _removeMainDeckCard(index),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  // エネルギーデッキタブの内容
  Widget _buildEnergyDeckTab() {
    return _energyDeckCards.isEmpty
        ? _buildEmptyState('エネルギーデッキにカードがありません', false)
        : GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _energyDeckCards.length,
            itemBuilder: (context, index) {
              return _buildCardItem(
                _energyDeckCards[index],
                onRemove: () => _removeEnergyDeckCard(index),
              );
            },
          );
  }
  
  // フィルターチップ
  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Colors.grey[200],
      selectedColor: Color(0xFFE4007F).withOpacity(0.2),
      checkmarkColor: Color(0xFFE4007F),
      labelStyle: TextStyle(
        color: isSelected ? Color(0xFFE4007F) : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
  
  // 空の状態のウィジェット
  Widget _buildEmptyState(String message, bool isMainDeck) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE4007F),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: Icon(Icons.add),
            label: Text(
              isMainDeck ? 'メインデッキカードを追加' : 'エネルギーカードを追加'
            ),
            onPressed: () => _addCards(isMainDeck: isMainDeck),
          ),
        ],
      ),
    );
  }
  
  // カードアイテム
  Widget _buildCardItem(BaseCard card, {required VoidCallback onRemove}) {
    Color borderColor;
    if (card is MemberCard) {
      borderColor = Colors.blue;
    } else if (card is LiveCard) {
      borderColor = Colors.purple;
    } else {
      borderColor = Colors.orange;
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // カード内容
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // カード画像
              Expanded(
                flex: 3,
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
                              child: Icon(Icons.broken_image, size: 40),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(Icons.image, size: 40),
                        ),
                      ),
              ),
              
              // カード情報
              Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: borderColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              card.rarity,
                              style: TextStyle(
                                color: borderColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // 削除ボタン
          Positioned(
            top: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRemove,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // メインデッキからカードを削除
  void _removeMainDeckCard(int index) {
    setState(() {
      _mainDeckCards.removeAt(index);
      _isDirty = true;
    });
  }
  
  // エネルギーデッキからカードを削除
  void _removeEnergyDeckCard(int index) {
    setState(() {
      _energyDeckCards.removeAt(index);
      _isDirty = true;
    });
  }
  
  // カード追加
  void _addCards({bool? isMainDeck}) {
    final currentTab = isMainDeck ?? (_tabController.index == 0);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardSearchScreen(
          cardTypeFilter: currentTab ? null : 'energy',
          selectionMode: true,
          initialSelectedCards: currentTab ? _mainDeckCards : _energyDeckCards,
          onCardsSelected: (selectedCards) {
            if (currentTab) {
              setState(() {
                _mainDeckCards = selectedCards.cast<BaseCard>();
                _isDirty = true;
              });
            } else {
              setState(() {
                _energyDeckCards = selectedCards.cast<EnergyCard>();
                _isDirty = true;
              });
            }
          },
        ),
      ),
    );
  }
  
  // デッキを保存
  Future<void> _saveDeck() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final updatedDeck = Deck(
        id: widget.deck.id,
        name: widget.deck.name,
        mainDeckCards: _mainDeckCards,
        energyDeckCards: _energyDeckCards,
        notes: widget.deck.notes,
      );
      
      await _dbHelper.updateDeck(updatedDeck);
      
      setState(() {
        _isDirty = false;
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('デッキを保存しました')),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }
  
  // 戻るボタン処理
  Future<bool> _onWillPop() async {
    if (!_isDirty) {
      return true;
    }
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('変更内容の保存'),
        content: Text('デッキに変更が加えられています。保存しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // 保存せずに戻る
            child: Text('保存せず戻る'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE4007F),
            ),
            onPressed: () async {
              await _saveDeck();
              Navigator.of(context).pop(true); // 保存して戻る
            },
            child: Text('保存して戻る'),
          ),
        ],
      ),
    ) ?? false;
  }
}