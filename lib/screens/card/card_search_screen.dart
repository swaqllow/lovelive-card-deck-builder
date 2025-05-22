import 'package:flutter/material.dart';
import '../../models/card/base_card.dart';
import '../../models/card/member_card.dart';
import '../../models/card/live_card.dart';
import '../../models/card/energy_card.dart';
import '../../models/enums/enums.dart';
import '../../services/database/database_helper.dart';

class CardSearchScreen extends StatefulWidget {
  final String? cardTypeFilter; // 'energy'の場合はエネルギーカードのみ表示
  final bool selectionMode; // 選択モードか閲覧モードか
  final List<dynamic>? initialSelectedCards; // 初期選択カード（デッキ編集時）
  final Function(List<dynamic>)? onCardsSelected; // カード選択時のコールバック
  
  const CardSearchScreen({
    super.key,
    this.cardTypeFilter,
    this.selectionMode = false,
    this.initialSelectedCards,
    this.onCardsSelected,
  });
  
  @override
  _CardSearchScreenState createState() => _CardSearchScreenState();
}

class _CardSearchScreenState extends State<CardSearchScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // 検索・フィルタリング状態
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCardType;
  String? _selectedRarity;
  SeriesName? _selectedSeries;
  HeartColor? _selectedHeartColor;
  String _sortOrder = 'name'; // デフォルトは名前順
  
  // カードデータ
  List<BaseCard> _allCards = [];
  List<BaseCard> _filteredCards = [];
  bool _isLoading = true;
  
  // 選択状態
  List<BaseCard> _selectedCards = [];
  
  @override
  void initState() {
    super.initState();
    
    // 初期選択カードがある場合（デッキ編集時）
    if (widget.initialSelectedCards != null) {
      _selectedCards = List<BaseCard>.from(widget.initialSelectedCards!);
    }
    
    // カードタイプフィルターが指定されている場合
    if (widget.cardTypeFilter != null) {
      _selectedCardType = widget.cardTypeFilter;
    }
    
    // カードデータの読み込み
    _loadCards();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // カードデータをロード
  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final cards = await _dbHelper.getAllCards();
      
      setState(() {
        _allCards = cards;
        _applyFilters(); // フィルターを適用
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('カードデータの読み込みに失敗しました: $e')),
      );
    }
  }
  
  // フィルター適用
  void _applyFilters() {
    List<BaseCard> result = List.from(_allCards);
    
    // 検索クエリでフィルタリング
    if (_searchQuery.isNotEmpty) {
      result = result.where((card) {
        final effectText = _getCardEffectText(card);
        return card.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               card.cardCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (effectText.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
    
    // カードタイプでフィルタリング
    if (_selectedCardType != null) {
      switch (_selectedCardType) {
        case 'member':
          result = result.whereType<MemberCard>().toList();
          break;
        case 'live':
          result = result.whereType<LiveCard>().toList();
          break;
        case 'energy':
          result = result.whereType<EnergyCard>().toList();
          break;
      }
    }
    
    // レアリティでフィルタリング
    if (_selectedRarity != null) {
      result = result.where((card) => card.rarity == _selectedRarity).toList();
    }
    
    // シリーズでフィルタリング
    if (_selectedSeries != null) {
      result = result.where((card) => card.series == _selectedSeries).toList();
    }
    
    // ハートカラーでフィルタリング（メンバーカードのみ）
    if (_selectedHeartColor != null) {
      result = result.where((card) {
        if (card is MemberCard) {
          return card.hearts.any((heart) => heart.color == _selectedHeartColor);
        }
        return false;
      }).toList();
    }
    
    // ソート
    switch (_sortOrder) {
      case 'name':
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'rarity':
        result.sort((a, b) => b.rarity.compareTo(a.rarity)); // 高レアリティ順
        break;
      case 'series':
        result.sort((a, b) => a.series.toString().compareTo(b.series.toString()));
        break;
    }
    
    setState(() {
      _filteredCards = result;
    });
  }
  
  // カードの効果テキストを取得
  String _getCardEffectText(BaseCard card) {
    if (card is MemberCard) {
      return card.effect;
    } else if (card is LiveCard) {
      return card.effect;
    }
    return '';
  }
  
  // カードの選択/選択解除
  void _toggleCardSelection(BaseCard card) {
    setState(() {
      if (_isCardSelected(card)) {
        _selectedCards.removeWhere((c) => c.id == card.id);
      } else {
        _selectedCards.add(card);
      }
    });
  }
  
  // カードが選択されているかチェック
  bool _isCardSelected(BaseCard card) {
    return _selectedCards.any((c) => c.id == card.id);
  }
  
  // 選択完了
  void _finishSelection() {
    if (widget.onCardsSelected != null) {
      widget.onCardsSelected!(_selectedCards);
    }
    Navigator.of(context).pop(_selectedCards);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('カード検索'),
        backgroundColor: Color(0xFFE4007F), // ラブライブピンク
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'カード名や効果で検索',
                fillColor: Colors.white,
                filled: true,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _applyFilters();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            ),
          ),
        ),
        actions: [
          // フィルターボタン
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'フィルター',
          ),
          
          // 選択モードの場合は選択完了ボタン
          if (widget.selectionMode)
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _finishSelection,
              tooltip: '選択完了',
            ),
        ],
      ),
      body: Column(
        children: [
          // 選択モードの場合は選択数表示
          if (widget.selectionMode)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '選択中: ${_selectedCards.length}枚',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.clear_all),
                    label: Text('選択解除'),
                    onPressed: _selectedCards.isNotEmpty
                        ? () {
                            setState(() {
                              _selectedCards.clear();
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
          
          // 現在のフィルター表示
          _buildActiveFiltersBar(),
          
          // カード一覧
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredCards.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: EdgeInsets.all(4),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4, // 列数を4に増やす
                          childAspectRatio: 0.65, // 縦長に調整
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: _filteredCards.length,
                        itemBuilder: (context, index) {
                          final card = _filteredCards[index];
                          final isSelected = _isCardSelected(card);
                          
                          return _buildCardItem(card, isSelected);
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  // アクティブなフィルターを表示するバー
  Widget _buildActiveFiltersBar() {
    List<Widget> filterChips = [];
    
    // カードタイプフィルター
    if (_selectedCardType != null) {
      String displayText;
      switch (_selectedCardType) {
        case 'member':
          displayText = 'メンバーカード';
          break;
        case 'live':
          displayText = 'ライブカード';
          break;
        case 'energy':
          displayText = 'エネルギーカード';
          break;
        default:
          displayText = _selectedCardType!;
      }
      
      filterChips.add(_buildFilterChip(
        label: displayText,
        onDeleted: () {
          setState(() {
            _selectedCardType = null;
          });
          _applyFilters();
        },
      ));
    }
    
    // レアリティフィルター
    if (_selectedRarity != null) {
      filterChips.add(_buildFilterChip(
        label: 'レアリティ: $_selectedRarity',
        onDeleted: () {
          setState(() {
            _selectedRarity = null;
          });
          _applyFilters();
        },
      ));
    }
    
    // シリーズフィルター
    if (_selectedSeries != null) {
      filterChips.add(_buildFilterChip(
        label: 'シリーズ: ${_selectedSeries!.displayName}',
        onDeleted: () {
          setState(() {
            _selectedSeries = null;
          });
          _applyFilters();
        },
      ));
    }
    
    // ハートカラーフィルター
    if (_selectedHeartColor != null) {
      filterChips.add(_buildFilterChip(
        label: 'ハート: ${_selectedHeartColor!.displayName}',
        onDeleted: () {
          setState(() {
            _selectedHeartColor = null;
          });
          _applyFilters();
        },
      ));
    }
    
    // ソート順表示
    String sortLabel;
    switch (_sortOrder) {
      case 'name':
        sortLabel = '名前順';
        break;
      case 'rarity':
        sortLabel = 'レアリティ順';
        break;
      case 'series':
        sortLabel = 'シリーズ順';
        break;
      default:
        sortLabel = _sortOrder;
    }
    
    filterChips.add(_buildFilterChip(
      label: 'ソート: $sortLabel',
      onDeleted: null, // ソートは常に何かしら適用されているので削除不可
      onTap: _showSortDialog,
    ));
    
    // フィルターがない場合は表示しない
    if (filterChips.isEmpty && _searchQuery.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          // 検索クエリがある場合は表示
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 4.0),
              child: Text(
                '検索: "$_searchQuery"',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE4007F),
                ),
              ),
            ),
          
          // フィルターチップをスクロール可能に表示
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: filterChips,
            ),
          ),
          
          // 検索結果件数
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '${_filteredCards.length}件',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // フィルターチップウィジェット
  Widget _buildFilterChip({
    required String label,
    VoidCallback? onDeleted,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: onTap,
        child: Chip(
          label: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFE4007F),
            ),
          ),
          backgroundColor: Color(0xFFE4007F).withOpacity(0.1),
          deleteIcon: onDeleted != null ? Icon(Icons.close, size: 16) : null,
          onDeleted: onDeleted,
          deleteButtonTooltipMessage: '削除',
        ),
      ),
    );
  }
  
  // 空の状態表示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            '検索条件に一致するカードがありません',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'フィルター条件を変更してみてください',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE4007F),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: Icon(Icons.clear_all),
            label: Text('フィルターをクリア'),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _selectedCardType = widget.cardTypeFilter; // カードタイプフィルターは維持
                _selectedRarity = null;
                _selectedSeries = null;
                _selectedHeartColor = null;
              });
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }
  
  // カードアイテム表示
  Widget _buildCardItem(BaseCard card, bool isSelected) {
    Color borderColor;
    if (card is MemberCard) {
      borderColor = Colors.blue;
    } else if (card is LiveCard) {
      borderColor = Colors.purple;
    } else {
      borderColor = Colors.orange;
    }
    
    final effectText = _getCardEffectText(card);
    
    return GestureDetector(
      onTap: widget.selectionMode
          ? () => _toggleCardSelection(card)
          : () => _showCardDetails(card),
      child: Card(
        elevation: isSelected ? 3 : 1,
        margin: EdgeInsets.all(2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isSelected ? Color(0xFFE4007F) : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // カード内容
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // カード画像（小さくする）
                Container(
                  height: 70, // 画像エリアを小さくする
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      card is MemberCard
                          ? Icons.person
                          : card is LiveCard
                              ? Icons.music_note
                              : Icons.flash_on,
                      size: 30,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                
                // カード情報
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // カード名とレアリティ
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                card.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 3,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: borderColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                card.rarity,
                                style: TextStyle(
                                  color: borderColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // カードシリーズ
                        Text(
                          card.series.displayName,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // 効果テキスト
                        if (effectText.isNotEmpty) ...[
                          SizedBox(height: 2),
                          Expanded(
                            child: Text(
                              effectText,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[800],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // 選択済みマーク
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Color(0xFFE4007F),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            
            // 詳細表示アイコン（選択モードでない場合）
            if (!widget.selectionMode)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.grey[600],
                    size: 10,
                  ),
                ),
              ),
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
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ヘッダー
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                color: card is MemberCard
                    ? Colors.blue
                    : card is LiveCard
                        ? Colors.purple
                        : Colors.orange,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        card.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        card.rarity,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // カード画像
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[200],
                child: Center(
                  child: Icon(
                    card is MemberCard
                        ? Icons.person
                        : card is LiveCard
                            ? Icons.music_note
                            : Icons.flash_on,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              
              // カード情報
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 基本情報
                    _buildDetailRow('カード番号', '${card.id}'),
                    _buildDetailRow('カードコード', card.cardCode),
                    _buildDetailRow('シリーズ', card.series.displayName),
                    if (card.unit != null)
                      _buildDetailRow('ユニット', card.unit!.displayName),
                    
                    Divider(height: 24),
                    
                    // カードタイプ別情報
                    if (card is MemberCard) ...[
                      _buildDetailRow('タイプ', 'メンバーカード'),
                      SizedBox(height: 8),
                      Text(
                        'ハート',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: card.hearts.map((heart) {
                          return Chip(
                            label: Text(
                              heart.color.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: _getColorForHeart(heart.color),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'ブレード',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text('${card.blades}'),
                        backgroundColor: Colors.grey[200],
                        ),  
                      if (card.effect.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Text(
                          '効果',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Text(card.effect),
                        ),
                      ],
                    ] else if (card is LiveCard) ...[
                      _buildDetailRow('タイプ', 'ライブカード'),
                      _buildDetailRow('スコア', '${card.score}'),
                      SizedBox(height: 8),
                      Text(
                        '必要ハート',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: card.requiredHearts.map((heart) {
                          return Chip(
                            label: Text(
                              heart.color.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: _getColorForHeart(heart.color),
                          );
                        }).toList(),
                      ),
                      if (card.effect.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Text(
                          '効果',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.purple.withOpacity(0.3),
                            ),
                          ),
                          child: Text(card.effect),
                        ),
                      ],
                    ] else if (card is EnergyCard) ...[
                      _buildDetailRow('タイプ', 'エネルギーカード'),
                    ],
                  ],
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
          if (widget.selectionMode)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE4007F),
              ),
              onPressed: () {
                _toggleCardSelection(card);
                Navigator.of(context).pop();
              },
              child: Text(
                _isCardSelected(card) ? '選択解除' : '選択する',
              ),
            ),
        ],
      ),
    );
  }
  
  // 詳細情報の行
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  // ハートカラーに対応する色を取得
  Color _getColorForHeart(HeartColor color) {
    switch (color) {
      case HeartColor.red:
        return Colors.red;
      case HeartColor.yellow:
        return Colors.amber;
      case HeartColor.purple:
        return Colors.purple;
      case HeartColor.pink:
        return Colors.pink;
      case HeartColor.green:
        return Colors.green;
      case HeartColor.blue:
        return Colors.blue;
      case HeartColor.any:
        return Colors.grey;
      //default:
      //  return Colors.grey;
    }
  }
  
  // フィルターダイアログ表示
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('フィルター設定'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // カードタイプフィルター
                  Text(
                    'カードタイプ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text('すべて'),
                        selected: _selectedCardType == null,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              _selectedCardType = null;
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text('メンバー'),
                        selected: _selectedCardType == 'member',
                        onSelected: widget.cardTypeFilter != 'energy'
                            ? (selected) {
                                if (selected) {
                                  setDialogState(() {
                                    _selectedCardType = 'member';
                                  });
                                }
                              }
                            : null,
                      ),
                      ChoiceChip(
                        label: Text('ライブ'),
                        selected: _selectedCardType == 'live',
                        onSelected: widget.cardTypeFilter != 'energy'
                            ? (selected) {
                                if (selected) {
                                  setDialogState(() {
                                    _selectedCardType = 'live';
                                  });
                                }
                              }
                            : null,
                      ),
                      ChoiceChip(
                        label: Text('エネルギー'),
                        selected: _selectedCardType == 'energy',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              _selectedCardType = 'energy';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // レアリティフィルター
                  Text(
                    'レアリティ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text('すべて'),
                        selected: _selectedRarity == null,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              _selectedRarity = null;
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text('N'),
                        selected: _selectedRarity == 'N',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              _selectedRarity = 'N';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text('R'),
                        selected: _selectedRarity == 'R',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              _selectedRarity = 'R';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text('SR'),
                        selected: _selectedRarity == 'SR',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              _selectedRarity = 'SR';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text('UR'),
                        selected: _selectedRarity == 'UR',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              _selectedRarity = 'UR';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text('LR'),
                        selected: _selectedRarity == 'LR',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              _selectedRarity = 'LR';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // シリーズフィルター
                  Text(
                    'シリーズ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text('すべて'),
                        selected: _selectedSeries == null,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              _selectedSeries = null;
                            });
                          }
                        },
                      ),
                      ...SeriesName.values.map((series) {
                        return ChoiceChip(
                          label: Text(series.displayName),
                          selected: _selectedSeries == series,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                _selectedSeries = series;
                              });
                            }
                          },
                        );
                      }),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // ハートカラーフィルター（メンバーカードのみ）
                  if (_selectedCardType != 'live' && _selectedCardType != 'energy') ...[
                    Text(
                      'ハートカラー',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text('すべて'),
                          selected: _selectedHeartColor == null,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                _selectedHeartColor = null;
                              });
                            }
                          },
                        ),
                        ...HeartColor.values.map((color) {
                          return ChoiceChip(
                            label: Text(
                              color.displayName,
                              style: TextStyle(
                                color: color == HeartColor.any ? Colors.black : Colors.white,
                              ),
                            ),
                            selected: _selectedHeartColor == color,
                            backgroundColor: _getColorForHeart(color).withOpacity(0.2),
                            selectedColor: _getColorForHeart(color),
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  _selectedHeartColor = color;
                                });
                              }
                            },
                          );
                        }),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              // フィルターリセットボタン
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    _selectedRarity = null;
                    _selectedSeries = null;
                    _selectedHeartColor = null;
                    _selectedCardType = widget.cardTypeFilter; // カードタイプフィルターは維持
                  });
                },
                child: Text('リセット'),
              ),
              
              // 適用ボタン
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE4007F),
                ),
                onPressed: () {
                  setState(() {
                    // ダイアログ内の選択を適用
                  });
                  _applyFilters();
                  Navigator.of(context).pop();
                },
                child: Text('適用'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // ソートダイアログ表示
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('ソート順'),
        children: [
          RadioListTile<String>(
            title: Text('名前順'),
            value: 'name',
            groupValue: _sortOrder,
            onChanged: (value) {
              setState(() {
                _sortOrder = value!;
              });
              _applyFilters();
              Navigator.of(context).pop();
            },
          ),
          RadioListTile<String>(
            title: Text('レアリティ順'),
            value: 'rarity',
            groupValue: _sortOrder,
            onChanged: (value) {
              setState(() {
                _sortOrder = value!;
              });
              _applyFilters();
              Navigator.of(context).pop();
            },
          ),
          RadioListTile<String>(
            title: Text('シリーズ順'),
            value: 'series',
            groupValue: _sortOrder,
            onChanged: (value) {
              setState(() {
                _sortOrder = value!;
              });
              _applyFilters();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}