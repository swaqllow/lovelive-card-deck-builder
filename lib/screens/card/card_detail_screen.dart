// lib/screens/card_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/card/base_card.dart';
import '../../models/card/member_card.dart';
import '../../models/card/live_card.dart';
import '../../models/card/energy_card.dart';
import '../../models/heart.dart';
import '../../models/enums/heart_color.dart';
import '../../models/enums/blade_heart.dart';
import '../../services/image_cache_service.dart';

class CardDetailScreen extends StatefulWidget {
  final BaseCard card;
  
  const CardDetailScreen({super.key, required this.card});
  
  @override
  _CardDetailScreenState createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  bool _isFavorite = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }
  
  // お気に入り状態の確認
  Future<void> _checkFavoriteStatus() async {
    // DBからお気に入り状態を確認する処理を実装
    // 仮の実装として、少し遅延後にランダムに設定
    await Future.delayed(Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _isFavorite = [true, false][DateTime.now().millisecond % 2];
      });
    }
  }
  
  // お気に入り状態の切り替え
  Future<void> _toggleFavorite() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // DBでお気に入り状態を切り替える処理を実装
      await Future.delayed(Duration(milliseconds: 300)); // 仮の遅延
      
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isLoading = false;
        });
        
        // SnackBarでフィードバックを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite 
                ? '${widget.card.name}をお気に入りに追加しました' 
                : '${widget.card.name}をお気に入りから削除しました'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // エラー表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // デッキ選択ダイアログを表示
  void _showAddToDeckDialog() {
    // 仮のデッキリスト
    final dummyDecks = [
      {'id': 1, 'name': 'μ\'s ストレートデッキ'},
      {'id': 2, 'name': 'Aqours スコアアップデッキ'},
      {'id': 3, 'name': '虹ヶ咲 コントロールデッキ'},
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('デッキに追加'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: dummyDecks.length,
            itemBuilder: (context, index) {
              final deck = dummyDecks[index];
              return ListTile(
                title: Text(deck['name'] as String),
                onTap: () {
                  Navigator.of(context).pop();
                  
                  // デッキに追加する処理を実装
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.card.name}を${deck['name']}に追加しました'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: Text('キャンセル'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('カード詳細'),
        backgroundColor: Color(0xFFE4007F),
        actions: [
          // お気に入りボタン
          _isLoading
              ? Container(
                  width: 48,
                  height: 48,
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // カード画像セクション
            _buildCardImageSection(),
            
            // カード基本情報
            _buildCardBasicInfo(),
            
            // カード効果・ハート等の詳細情報
            _buildCardDetailInfo(),
            
            // 操作ボタン
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('デッキに追加'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE4007F),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _showAddToDeckDialog,
                  ),
                  OutlinedButton.icon(
                    icon: Icon(Icons.share),
                    label: Text('共有'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFFE4007F),
                      side: BorderSide(color: Color(0xFFE4007F)),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      // 共有機能の実装
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('共有機能は準備中です')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // カード画像セクション
  Widget _buildCardImageSection() {
    final imageCacheService = Provider.of<ImageCacheService>(context, listen: false);
    
    return Container(
      height: 300,
      color: Colors.black.withOpacity(0.05),
      child: FutureBuilder<ImageProvider>(
        future: imageCacheService.getImage(widget.card.imageUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
            return Image(
              image: snapshot.data!,
              fit: BoxFit.contain,
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
  
  // カード基本情報
  Widget _buildCardBasicInfo() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCardTypeColor(widget.card.cardType),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getCardTypeDisplayName(widget.card.cardType),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRarityColor(widget.card.rarity),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.card.rarity,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              widget.card.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'シリーズ: ${_getSeriesDisplayName(widget.card.series.toString())}',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            if (widget.card.unit != null) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.group, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'ユニット: ${_getUnitDisplayName(widget.card.unit.toString())}',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '収録: ${widget.card.productSet}',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.tag, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'カードID: ${widget.card.id}',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // カード詳細情報
  Widget _buildCardDetailInfo() {
    if (widget.card is MemberCard) {
      return _buildMemberCardDetails(widget.card as MemberCard);
    } else if (widget.card is LiveCard) {
      return _buildLiveCardDetails(widget.card as LiveCard);
    } else if (widget.card is EnergyCard) {
      return _buildEnergyCardDetails(widget.card as EnergyCard);
    } else {
      return SizedBox.shrink();
    }
  }
  
  // メンバーカード詳細
  Widget _buildMemberCardDetails(MemberCard card) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // コスト
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'コスト: ${card.cost}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // ハート
            Text(
              'ハート',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            card.hearts.isEmpty
                ? Text('なし', style: TextStyle(fontStyle: FontStyle.italic))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: card.hearts.map((heart) {
                      return _buildHeartChip(heart);
                    }).toList(),
                  ),
            SizedBox(height: 16),
            
            // ブレード
            Text(
              'ブレード',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            card.blades <= 0
              ? Text('なし', style: TextStyle(fontStyle: FontStyle.italic))
              : Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    card.blades.toString(),
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          SizedBox(height: 16),
            
            // ブレードハート
          Text(
            'ブレードハート',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          card.bladeHearts.typeCount <= 0
              ? Text('なし', style: TextStyle(fontStyle: FontStyle.italic))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: BladeHeartType.values
                      .where((type) => card.bladeHearts.hasType(type))
                      .map((type) {
                    return _buildBladeHeartTypeChip(type, card.bladeHearts.quantityOf(type));
                  }).toList(),
                ),
            SizedBox(height: 16),
            
            // 効果
            Text(
              '効果',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            card.effect.isEmpty
                ? Text('効果なし', style: TextStyle(fontStyle: FontStyle.italic))
                : Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(card.effect),
                  ),
          ],
        ),
      ),
    );
  }
  
  // ライブカード詳細
  Widget _buildLiveCardDetails(LiveCard card) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // スコア
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'スコア: ${card.score}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // 必要ハート
            Text(
              '必要ハート',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            card.requiredHearts.isEmpty
                ? Text('なし', style: TextStyle(fontStyle: FontStyle.italic))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: card.requiredHearts.map((heart) {
                      return _buildHeartChip(heart);
                    }).toList(),
                  ),
            SizedBox(height: 16),
            
            // ブレードハート
            Text(
              'ブレードハート',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            card.bladeHearts.typeCount <= 0
                ? Text('なし', style: TextStyle(fontStyle: FontStyle.italic))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: BladeHeartType.values
                      .where((type) => card.bladeHearts.hasType(type))
                      .map((type) {
                    return _buildBladeHeartTypeChip(type, card.bladeHearts.quantityOf(type));
                    }).toList(),
                  ),
            SizedBox(height: 16),
            
            // 効果
            Text(
              '効果',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            card.effect.isEmpty
                ? Text('効果なし', style: TextStyle(fontStyle: FontStyle.italic))
                : Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(card.effect),
                  ),
          ],
        ),
      ),
    );
  }
  
  // エネルギーカード詳細
  Widget _buildEnergyCardDetails(EnergyCard card) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'エネルギーカード',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'このカードはエネルギーデッキに入れて使用します。ゲーム開始時にエネルギーデッキから1枚ずつドローし、'
                'ライブカードやメンバーカードのコストとして使用します。',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ハートを表示するチップ
  Widget _buildHeartChip(Heart heart) {
    final color = _getHeartColor(heart.color);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            color: color,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            heart.color.displayName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  // ブレードハートを表示するチップ
  Widget _buildBladeHeartTypeChip(BladeHeartType type, int quantity) {
  final backgroundColor = _getBladeHeartTypeColor(type);
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: backgroundColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: backgroundColor),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getIconForBladeHeartType(type),
          color: backgroundColor,
          size: 16,
        ),
        SizedBox(width: 4),
        Text(
          '${_getBladeHeartTypeDisplayName(type)} x $quantity',
          style: TextStyle(
            color: backgroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
  
  // カードタイプに応じた表示色を取得
  Color _getCardTypeColor(String cardType) {
    switch (cardType) {
      case 'member':
        return Colors.purple;
      case 'live':
        return Colors.blue;
      case 'energy':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  // カードタイプの表示名を取得
  String _getCardTypeDisplayName(String cardType) {
    switch (cardType) {
      case 'member':
        return 'メンバー';
      case 'live':
        return 'ライブ';
      case 'energy':
        return 'エネルギー';
      default:
        return cardType;
    }
  }
  
  // レアリティに応じた表示色を取得
  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'ur':
        return Colors.red;
      case 'sr':
        return Colors.purple;
      case 'r':
        return Colors.blue;
      case 'n':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  // ハートの色を取得
  Color _getHeartColor(HeartColor heartColor) {
    switch (heartColor) {
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
  
  // ブレードハートタイプの色を取得
  Color _getBladeHeartTypeColor(BladeHeartType type) {
    switch (type) {
      case BladeHeartType.normal:
        return Colors.blue;
      case BladeHeartType.utility:
        return Colors.teal;
      case BladeHeartType.draw:
        return Colors.purple;
      case BladeHeartType.scoreUp:
        return Colors.orange;
      //default:
      //  return Colors.grey;
    }
  }
  
  // ブレードハートタイプの表示名を取得
  String _getBladeHeartTypeDisplayName(BladeHeartType type) {
    switch (type) {
      case BladeHeartType.normal:
        return '通常';
      case BladeHeartType.utility:
        return 'ユーティリティ';
      case BladeHeartType.draw:
        return 'ドロー';
      case BladeHeartType.scoreUp:
        return 'スコアアップ';
      // default:
      //  return '不明';
    }
  }
  
  // シリーズ名の表示名変換
  String _getSeriesDisplayName(String seriesName) {
    final series = seriesName.split('.').last;
    
    switch (series) {
      case 'loveLive':
        return 'ラブライブ！';
      case 'sunshine':
        return 'ラブライブ！サンシャイン!!';
      case 'nijigasaki':
        return 'ラブライブ！虹ヶ咲学園スクールアイドル同好会';
      case 'superstar':
        return 'ラブライブ！スーパースター!!';
      case 'hasunosoraGakuin':
        return 'ラブライブ！蓮ノ空女学院スクールアイドルクラブ';
      default:
        return series;
    }
  }
  
  // ユニット名の表示名変換
  String _getUnitDisplayName(String unitName) {
    final unit = unitName.split('.').last;
    
    switch (unit) {
      case 'muse':
        return 'μ\'s';
      case 'bibi':
        return 'BiBi';
      case 'printemps':
        return 'Printemps';
      case 'lillyWhite':
        return 'lily white';
      // その他のユニットも同様に追加
      default:
        return unit;
    }
  }
  // ブレードハートタイプに応じたアイコンを取得するメソッド
IconData _getIconForBladeHeartType(BladeHeartType type) {
  switch (type) {
    case BladeHeartType.normal:
      return Icons.shuffle;
    case BladeHeartType.utility:
      return Icons.build;
    case BladeHeartType.draw:
      return Icons.style;
    case BladeHeartType.scoreUp:
      return Icons.trending_up;
  }
}
}