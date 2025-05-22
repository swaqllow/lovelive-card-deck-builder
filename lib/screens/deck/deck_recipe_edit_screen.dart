// lib/screens/deck_edit_screen.dart
import 'package:flutter/material.dart';
import '../../models/deck.dart';
import '../../models/card/base_card.dart';
import '../../models/card/member_card.dart';
import '../../models/card/live_card.dart';
import '../../models/card/energy_card.dart';
import '../../services/database/database_helper.dart';
import '../../services/image_cache_service.dart';
import '../card/card_search_screen.dart';
import 'deck_report_screen.dart';
import 'package:provider/provider.dart';

enum DeckType {
  main,
  energy,
}

enum CardFilter {
  all,
  member,
  live,
  energy,
}

class DeckRecipeEditScreen extends StatefulWidget {
  final Deck deck;
  
  const DeckRecipeEditScreen({super.key, required this.deck});
  
  @override
  _DeckRecipeEditScreenState createState() => _DeckRecipeEditScreenState();
}

class _DeckRecipeEditScreenState extends State<DeckRecipeEditScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DatabaseHelper _dbHelper;
  bool _isDirty = false;
  DeckType _currentDeckType = DeckType.main;
  CardFilter _currentFilter = CardFilter.all;
  
  // 現在のデッキタイプに応じたカードリスト
  List<BaseCard> get _currentCards {
    if (_currentDeckType == DeckType.main) {
      return _filteredMainDeckCards;
    } else {
      return widget.deck.energyDeckCards;
    }
  }
  
  // フィルタリングされたメインデッキカード
  List<BaseCard> get _filteredMainDeckCards {
    switch (_currentFilter) {
      case CardFilter.all:
        return widget.deck.mainDeckCards;
      case CardFilter.member:
        return widget.deck.mainDeckCards
            .whereType<MemberCard>()
            .toList();
      case CardFilter.live:
        return widget.deck.mainDeckCards
            .whereType<LiveCard>()
            .toList();
      default:
        return widget.deck.mainDeckCards;
    }
  }
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dbHelper = DatabaseHelper();
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentDeckType = _tabController.index == 0 ? DeckType.main : DeckType.energy;
          // エネルギーデッキに切り替えたらフィルターをリセット
          if (_currentDeckType == DeckType.energy) {
            _currentFilter = CardFilter.all;
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('デッキ編集'),
          backgroundColor: Color(0xFFE4007F),
          actions: [
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveDeck,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'メインデッキ'),
              Tab(text: 'エネルギーデッキ'),
            ],
          ),
        ),
        body: Column(
          children: [
            // デッキ情報セクション
            _buildDeckInfoSection(),
            
            // フィルターセクション（メインデッキの場合のみ表示）
            if (_currentDeckType == DeckType.main)
              _buildFilterSection(),
            
            // カード一覧表示部分
            Expanded(
              child: _currentCards.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _currentCards.length,
                      itemBuilder: (context, index) {
                        return _buildCardItem(_currentCards[index], index);
                      },
                    ),
            ),
            
            // ステータスバー
            _buildStatusBar(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Color(0xFFE4007F),
          onPressed: _navigateToCardSearch,
          tooltip: 'カードを追加',
          child: Icon(Icons.add),
        ),
      ),
    );
  }
  
  // デッキ情報セクション
  Widget _buildDeckInfoSection() {
    if (_currentDeckType == DeckType.main) {
      // メインデッキの情報
      return Container(
        padding: EdgeInsets.all(16),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'メインデッキ: ${widget.deck.mainDeckSize}/60枚',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: Icon(Icons.sort, color: Color(0xFFE4007F)),
                  label: Text(
                    '並び替え',
                    style: TextStyle(color: Color(0xFFE4007F)),
                  ),
                  onPressed: _showSortOptions,
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'メンバーカード: ${widget.deck.memberCardCount}/48枚 • ライブカード: ${widget.deck.liveCardCount}/12枚',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    } else {
      // エネルギーデッキの情報
      return Container(
        padding: EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'エネルギーデッキ: ${widget.deck.energyDeckSize}/12枚',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              icon: Icon(Icons.sort, color: Color(0xFFE4007F)),
              label: Text(
                '並び替え',
                style: TextStyle(color: Color(0xFFE4007F)),
              ),
              onPressed: _showSortOptions,
            ),
          ],
        ),
      );
    }
  }
  
  // フィルターセクション
  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'すべて',
            isSelected: _currentFilter == CardFilter.all,
            onTap: () => _setFilter(CardFilter.all),
          ),
          SizedBox(width: 8),
          _buildFilterChip(
            label: 'メンバー',
            isSelected: _currentFilter == CardFilter.member,
            onTap: () => _setFilter(CardFilter.member),
          ),
          SizedBox(width: 8),
          _buildFilterChip(
            label: 'ライブ',
            isSelected: _currentFilter == CardFilter.live,
            onTap: () => _setFilter(CardFilter.live),
          ),
        ],
      ),
    );
  }
  
  // フィルターチップ
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFE4007F).withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? Color(0xFFE4007F) : Colors.grey[400]!,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Color(0xFFE4007F) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  // ステータスバー
  Widget _buildStatusBar() {
    bool isValid = widget.deck.isValid();
    String statusText = '';
    
    if (_currentDeckType == DeckType.main) {
      statusText = 'メインデッキ: ${widget.deck.mainDeckSize}/60枚';
    } else {
      statusText = 'エネルギーデッキ: ${widget.deck.energyDeckSize}/12枚';
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              color: isValid ? Colors.black : Colors.red,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeckReportScreen(deck: widget.deck),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE4007F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text('デッキ確認'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    String message = _currentDeckType == DeckType.main
        ? 'メインデッキにカードが追加されていません'
        : 'エネルギーデッキにカードが追加されていません';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(message),
          SizedBox(height: 8),
          Text('右下の「+」ボタンからカードを追加しましょう'),
        ],
      ),
    );
  }
  
  Widget _buildCardItem(BaseCard card, int index) {
    // カードの種類に応じた色を選択
    Color cardColor;
    if (card is MemberCard) {
      cardColor = Colors.purple.withOpacity(0.1);
    } else if (card is LiveCard) {
      cardColor = Colors.blue.withOpacity(0.1);
    } else {
      cardColor = Colors.orange.withOpacity(0.1);
    }
    
    return Stack(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // カード画像
              Expanded(
                child: FutureBuilder<bool>(
                  future: _checkImageAvailability(card.imageUrl),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done && 
                        snapshot.data == true) {
                      return Image.network(
                        card.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      );
                    } else {
                      return Container(
                        color: cardColor,
                        width: double.infinity,
                        height: double.infinity,
                        child: Center(
                          child: Text(
                            card.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                  },
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
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    _buildCardTypeInfo(card),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // カードタイプバッジ
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: _getCardTypeColor(card),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Text(
              _getCardTypeLabel(card),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        // 削除ボタン
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _removeCard(index),
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
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
      ],
    );
  }
  
  Widget _buildCardTypeInfo(BaseCard card) {
    if (card is MemberCard) {
      return Row(
        children: [
          Icon(Icons.star, size: 14, color: Colors.amber),
          SizedBox(width: 4),
          Text(
            'コスト: ${card.cost}',
            style: TextStyle(fontSize: 12),
          ),
        ],
      );
    } else if (card is LiveCard) {
      return Row(
        children: [
          Icon(Icons.music_note, size: 14, color: Colors.blue),
          SizedBox(width: 4),
          Text(
            'Score: ${card.score}',
            style: TextStyle(fontSize: 12),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Icon(Icons.bolt, size: 14, color: Colors.orange),
          SizedBox(width: 4),
          Text(
            'エネルギー',
            style: TextStyle(fontSize: 12),
          ),
        ],
      );
    }
  }
  
  Color _getCardTypeColor(BaseCard card) {
    if (card is MemberCard) {
      return Color(0xFF9C27B0); // パープル
    } else if (card is LiveCard) {
      return Color(0xFF2196F3); // ブルー
    } else {
      return Color(0xFFFF9800); // オレンジ
    }
  }
  
  String _getCardTypeLabel(BaseCard card) {
    if (card is MemberCard) {
      return 'メンバー';
    } else if (card is LiveCard) {
      return 'ライブ';
    } else {
      return 'エネルギー';
    }
  }
  
  // 画像が利用可能かチェック
  Future<bool> _checkImageAvailability(String url) async {
    if (url.isEmpty) return false;
    
    final imageCacheService = Provider.of<ImageCacheService>(context, listen: false);
    return await imageCacheService.isImageCached(url);
  }
  
  void _setFilter(CardFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
  }
  
  void _removeCard(int index) {
    setState(() {
      if (_currentDeckType == DeckType.main) {
        // メインデッキからカードを削除
        final cardToRemove = _currentCards[index];
        widget.deck.mainDeckCards.remove(cardToRemove);
      } else {
        // エネルギーデッキからカードを削除
        widget.deck.energyDeckCards.removeAt(index);
      }
      _isDirty = true;
    });
  }
  
  Future<void> _navigateToCardSearch() async {
    // 現在のデッキタイプに基づいて、追加可能なカードタイプを絞り込む
    CardFilter requiredFilter = _currentDeckType == DeckType.main
        ? CardFilter.all
        : CardFilter.energy;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardSearchScreen(
          cardTypeFilter: requiredFilter.toString(),
          selectionMode: true,
        ),
      ),
    );
    
    if (result != null && result is List<BaseCard>) {
      setState(() {
        if (_currentDeckType == DeckType.main) {
          // メインデッキにカードを追加
          widget.deck.mainDeckCards.addAll(result);
        } else {
          // エネルギーデッキにカードを追加
          for (var card in result) {
            if (card is EnergyCard) {
              widget.deck.energyDeckCards.add(card);
            }
          }
        }
        _isDirty = true;
      });
    }
  }
  
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.sort_by_alpha),
            title: Text('名前順'),
            onTap: () {
              Navigator.pop(context);
              _sortCards('name');
            },
          ),
          if (_currentDeckType == DeckType.main) ...[
            ListTile(
              leading: Icon(Icons.star),
              title: Text('コスト順'),
              onTap: () {
                Navigator.pop(context);
                _sortCards('cost');
              },
            ),
            ListTile(
              leading: Icon(Icons.category),
              title: Text('カードタイプ順'),
              onTap: () {
                Navigator.pop(context);
                _sortCards('type');
              },
            ),
          ],
        ],
      ),
    );
  }
  
  void _sortCards(String sortBy) {
    setState(() {
      if (_currentDeckType == DeckType.main) {
        // メインデッキのソート
        switch (sortBy) {
          case 'name':
            widget.deck.mainDeckCards.sort((a, b) => a.name.compareTo(b.name));
            break;
          case 'cost':
            widget.deck.mainDeckCards.sort((a, b) {
              // メンバーカードのコスト比較
              if (a is MemberCard && b is MemberCard) {
                return b.cost.compareTo(a.cost); // 降順
              }
              // カードタイプの優先順位
              if (a is MemberCard && b is LiveCard) return -1;
              if (a is LiveCard && b is MemberCard) return 1;
              return 0;
            });
            break;
          case 'type':
            widget.deck.mainDeckCards.sort((a, b) {
              // メンバーカード → ライブカードの順
              if (a is MemberCard && b is LiveCard) return -1;
              if (a is LiveCard && b is MemberCard) return 1;
              
              // 同タイプならコスト順
              if (a is MemberCard && b is MemberCard) {
                return b.cost.compareTo(a.cost); // 降順
              }
              if (a is LiveCard && b is LiveCard) {
                return b.score.compareTo(a.score); // 降順
              }
              return 0;
            });
            break;
        }
      } else {
        // エネルギーデッキのソート
        widget.deck.energyDeckCards.sort((a, b) => a.name.compareTo(b.name));
      }
      _isDirty = true;
    });
  }
  
  Future<void> _saveDeck() async {
    try {
      // デッキを保存
      await _dbHelper.updateDeck(widget.deck);
      
      setState(() {
        _isDirty = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('デッキを保存しました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }
  
  Future<bool> _onWillPop() async {
    if (!_isDirty) {
      return true;
    }
    
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('編集内容を保存しますか？'),
        content: Text('変更内容が保存されていません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              _saveDeck();
              Navigator.of(context).pop(true);
            },
            child: Text('保存'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('保存せずに戻る'),
          ),
        ],
      ),
    ) ?? false;
  }
}