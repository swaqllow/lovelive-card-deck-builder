// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/card_data_provider.dart';
import '../../models/card/base_card.dart';
import '../../models/card/member_card.dart';
import '../../models/card/live_card.dart';
import '../../models/deck.dart';
import '../../services/database/database_helper.dart';
import '../../services/image_cache_service.dart';
import '../../services/sample_data_service.dart';
import '../test_scraping_screen.dart';
import '../settings_screen.dart';
import '../deck/deck_report_screen.dart';
import '../deck/deck_edit_screen.dart';
import '../card/card_detail_screen.dart';
import '../html_structure_viewer.dart';
import '../test_diagnosis_screen.dart';
import '../test_database_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4つのタブに変更
    
    // カードデータの更新チェック（バックグラウンドで実行）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }
  
  // 更新チェック
  Future<void> _checkForUpdates() async {
    final cardDataProvider = Provider.of<CardDataProvider>(context, listen: false);
    final hasUpdates = await cardDataProvider.checkForUpdates();
    
    if (hasUpdates && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('カードデータの更新があります。設定から更新してください。'),
          action: SnackBarAction(
            label: '更新',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ラブライブ！デッキビルダー'),
        backgroundColor: Color(0xFFE4007F),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'カード一覧'),
            Tab(text: 'デッキ一覧'),
            Tab(text: 'お気に入り'),
            Tab(text: 'デバッグ'),  // デバッグタブを追加
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CardCollectionTab(),
          DeckListTab(),
          FavoritesTab(),
          DebugTab(),  // デバッグタブを追加
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFE4007F),
        child: Icon(Icons.add),
        onPressed: () {
          _showCreateDeckDialog();
        },
      ),
    );
  }
  
  // 検索ダイアログ
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('カード検索'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'カード名',
                  hintText: 'カード名を入力',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              SizedBox(height: 16),
              // ここに追加のフィルターオプションを配置
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('キャンセル'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text('検索'),
            onPressed: () {
              // 検索処理
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
  
  // デッキ作成ダイアログ
  void _showCreateDeckDialog() {
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('新しいデッキを作成'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'デッキ名',
            hintText: 'デッキ名を入力してください',
          ),
        ),
        actions: [
          TextButton(
            child: Text('キャンセル'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text('作成'),
            onPressed: () {
              final deckName = nameController.text.trim();
              if (deckName.isNotEmpty) {
                // 新規デッキを作成してデッキ編集画面に遷移
                final newDeck = Deck(
                  name: deckName,
                  mainDeckCards: [],
                  energyDeckCards: [],
                );
                
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeckEditScreen(deck: newDeck),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// デバッグタブの追加
class DebugTab extends StatelessWidget {
  const DebugTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text(
          'デバッグメニュー',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 16),
        
        // デバッグボタンカード
        Card(
          color: Colors.grey[50],
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 接続診断ボタン
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48),
                  ),
                  icon: Icon(Icons.wifi_find),
                  label: Text('接続診断'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TestDiagnosisScreen(),
                      ),
                    );
                  },
                ),
                
                // データベース診断ボタン
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48),
                  ),
                  icon: Icon(Icons.storage),
                  label: Text('データベース診断'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DatabaseTestScreen(),
                      ),
                    );
                  },
                ),
                
                // HTML構造解析ボタン
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48),
                  ),
                  icon: Icon(Icons.code),
                  label: Text('HTML構造解析'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => HtmlStructureViewer(),
                      ),
                    );
                  },
                ),
                
                // スクレイピングテストボタン
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48),
                  ),
                  icon: Icon(Icons.download),
                  label: Text('スクレイピングテスト'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TestScrapingScreen(),
                      ),
                    );
                  },
                ),
                
                // サンプルデータ生成ボタン
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48),
                  ),
                  icon: Icon(Icons.add_box),
                  label: Text('サンプルデータ生成'),
                  onPressed: () async {
                    final sampleService = SampleDataService();
                    await sampleService.saveSampleDataToDatabase();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('サンプルデータを保存しました')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 32),
        
        // クイックアクションカード
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'クイックアクション',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                
                ListTile(
                  leading: Icon(Icons.bug_report, color: Colors.red),
                  title: Text('ログをクリア'),
                  subtitle: Text('デバッグログとキャッシュを削除'),
                  onTap: () {
                    _showClearCacheDialog(context);
                  },
                ),
                
                Divider(),
                
                ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.blue),
                  title: Text('アプリ情報'),
                  subtitle: Text('バージョン: 1.0.0 (Debug)'),
                  onTap: () {
                    _showAppInfoDialog(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // キャッシュクリアダイアログ
  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('キャッシュをクリア'),
        content: Text('すべてのログとキャッシュデータを削除します。\nこの操作は元に戻せません。'),
        actions: [
          TextButton(
            child: Text('キャンセル'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              // キャッシュクリア処理
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('キャッシュを削除しました')),
              );
            },
          ),
        ],
      ),
    );
  }
  
  // アプリ情報ダイアログ
  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('アプリ情報'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ラブライブ！デッキビルダー'),
            SizedBox(height: 8),
            Text('バージョン: 1.0.0'),
            Text('ビルド: Debug'),
            SizedBox(height: 16),
            Text('開発者: Your Name'),
            Text('最終更新: ${DateTime.now().toLocal()}'),
          ],
        ),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

// カード一覧タブ
class CardCollectionTab extends StatefulWidget {
  const CardCollectionTab({super.key});

  @override
  _CardCollectionTabState createState() => _CardCollectionTabState();
}

class _CardCollectionTabState extends State<CardCollectionTab> with SingleTickerProviderStateMixin {
  late TabController _cardTypeTabController;
  
  @override
  void initState() {
    super.initState();
    _cardTypeTabController = TabController(length: 3, vsync: this);
    _cardTypeTabController.addListener(() {
      if (_cardTypeTabController.indexIsChanging) {
        setState(() {
          int selectedCardTypeIndex = _cardTypeTabController.index;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _cardTypeTabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // カードタイプ選択タブ
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _cardTypeTabController,
            labelColor: Color(0xFFE4007F),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFE4007F),
            tabs: [
              Tab(text: 'メンバー'),
              Tab(text: 'ライブ'),
              Tab(text: 'エネルギー'),
            ],
          ),
        ),
        
        // カード一覧表示
        Expanded(
          child: TabBarView(
            controller: _cardTypeTabController,
            children: [
              _buildCardGrid('member'),
              _buildCardGrid('live'),
              _buildCardGrid('energy'),
            ],
          ),
        ),
      ],
    );
  }
  
  // カードグリッド表示
  Widget _buildCardGrid(String cardType) {
    final cardDataProvider = Provider.of<CardDataProvider>(context);
    
    if (cardDataProvider.isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    
    final cards = cardDataProvider.getCardsByType(cardType);
    
    if (cards.isEmpty) {
      return Center(
        child: Text('カードがありません'),
      );
    }
    
    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,  // 1行あたりのカード数
        childAspectRatio: 0.7,  // カードの縦横比
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return _buildCardItem(cards[index]);
      },
    );
  }
  
  // カードアイテム表示
  Widget _buildCardItem(BaseCard card) {
    return GestureDetector(
      onTap: () {
        // カード詳細画面に遷移
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CardDetailScreen(card: card),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // カード画像
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                child: _buildCardImage(card),
              ),
            ),
            
            // カード名
            Padding(
              padding: EdgeInsets.all(4),
              child: Text(
                card.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // カード情報（タイプ別に表示内容を変更）
            Padding(
              padding: EdgeInsets.only(left: 4, right: 4, bottom: 4),
              child: _buildCardInfo(card),
            ),
          ],
        ),
      ),
    );
  }
  
  // カード画像の表示
  Widget _buildCardImage(BaseCard card) {
    final imageCacheService = Provider.of<ImageCacheService>(context, listen: false);
    
    return FutureBuilder<bool>(
      future: imageCacheService.isImageCached(card.imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data == true) {
          // キャッシュされた画像を表示
          return FutureBuilder<ImageProvider>(
            future: imageCacheService.getImage(card.imageUrl),
            builder: (context, imageSnapshot) {
              if (imageSnapshot.connectionState == ConnectionState.done && imageSnapshot.data != null) {
                return Image(
                  image: imageSnapshot.data!,
                  fit: BoxFit.cover,
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          );
        } else {
          // キャッシュされていない場合はプレースホルダを表示
          return Center(
            child: Icon(Icons.image, size: 40, color: Colors.grey),
          );
        }
      },
    );
  }
  
  // カードタイプに応じた情報表示
  Widget _buildCardInfo(BaseCard card) {
    if (card is MemberCard) {
      // メンバーカード固有の情報
      return Row(
        children: [
          Expanded(
            child: Text(
              '${card.series.toString().split('.').last} / コスト: ${card.cost}',
              style: TextStyle(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else if (card is LiveCard) {
      // ライブカード固有の情報
      return Row(
        children: [
          Expanded(
            child: Text(
              '${card.series.toString().split('.').last} / スコア: ${card.score}',
              style: TextStyle(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      // エネルギーカード
      return Row(
        children: [
          Expanded(
            child: Text(
              card.series.toString().split('.').last,
              style: TextStyle(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
  }
}

// デッキ一覧タブ
class DeckListTab extends StatefulWidget {
  const DeckListTab({super.key});

  @override
  _DeckListTabState createState() => _DeckListTabState();
}

class _DeckListTabState extends State<DeckListTab> {
  List<Deck> _decks = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadDecks();
  }
  
  // デッキ一覧を読み込み
  Future<void> _loadDecks() async {
    final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // DBからデッキを取得する処理
      // 実際の実装ではdbHelperのメソッドを呼び出し
      await Future.delayed(Duration(milliseconds: 500)); // 仮の遅延
      
      // 仮のデータセット
      final dummyDecks = [
        Deck(
          id: 1,
          name: 'μ\'s ストレートデッキ',
          mainDeckCards: [],
          energyDeckCards: [],
        ),
        Deck(
          id: 2,
          name: 'Aqours スコアアップデッキ',
          mainDeckCards: [],
          energyDeckCards: [],
        ),
        Deck(
          id: 3,
          name: '虹ヶ咲 コントロールデッキ',
          mainDeckCards: [],
          energyDeckCards: [],
        ),
      ];
      
      setState(() {
        _decks = dummyDecks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading decks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_decks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_customize, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'デッキがありません',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('新しいデッキを作成'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE4007F),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // デッキ作成ダイアログ表示
                (context as Element).findAncestorStateOfType<_HomeScreenState>()!
                    ._showCreateDeckDialog();
              },
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: _decks.length,
      itemBuilder: (context, index) {
        final deck = _decks[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              deck.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                Icon(Icons.style, size: 14),
                SizedBox(width: 4),
                Text('メインデッキ: ${deck.mainDeckSize}枚'),
                SizedBox(width: 8),
                Icon(Icons.bolt, size: 14),
                SizedBox(width: 4),
                Text('エネルギー: ${deck.energyDeckSize}枚'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                // 選択されたメニュー項目に応じた処理
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeckEditScreen(deck: deck),
                    ),
                  );
                } else if (value == 'report') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeckReportScreen(deck: deck),
                    ),
                  );
                } else if (value == 'delete') {
                  _showDeleteDeckDialog(deck);
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('編集'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.assessment, color: Colors.green),
                      SizedBox(width: 8),
                      Text('レポート'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('削除'),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeckEditScreen(deck: deck),
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  // デッキ削除確認ダイアログ
  void _showDeleteDeckDialog(Deck deck) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('デッキの削除'),
        content: Text('「${deck.name}」を削除しますか？この操作は元に戻せません。'),
        actions: [
          TextButton(
            child: Text('キャンセル'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              // デッキ削除処理
              Navigator.of(context).pop();
              // 削除後にデッキ一覧を再読み込み
              _loadDecks();
            },
          ),
        ],
      ),
    );
  }
}

// お気に入りタブ
class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  _FavoritesTabState createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  bool _isLoading = true;
  List<BaseCard> _favoriteCards = [];
  List<Deck> _favoriteDecks = [];
  
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }
  
  // お気に入りデータの読み込み
  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // DBからお気に入りを取得する処理
      await Future.delayed(Duration(milliseconds: 500)); // 仮の遅延
      
      // 仮のデータ
      setState(() {
        _favoriteCards = [];
        _favoriteDecks = [];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading favorites: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_favoriteCards.isEmpty && _favoriteDecks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'お気に入りがありません',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'カードやデッキをお気に入りに追加すると\nここに表示されます',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Color(0xFFE4007F),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFFE4007F),
              tabs: [
                Tab(text: 'お気に入りカード'),
                Tab(text: 'お気に入りデッキ'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFavoriteCardsGrid(),
                _buildFavoriteDeckslist(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // お気に入りカードのグリッド表示
  Widget _buildFavoriteCardsGrid() {
    if (_favoriteCards.isEmpty) {
      return Center(
        child: Text('お気に入りのカードがありません'),
      );
    }
    
    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _favoriteCards.length,
      itemBuilder: (context, index) {
        // CardCollectionTabと同様のカード表示
        return Container(); // 簡略化のため空のコンテナを返す
      },
    );
  }
  
  // お気に入りデッキのリスト表示
  Widget _buildFavoriteDeckslist() {
    if (_favoriteDecks.isEmpty) {
      return Center(
        child: Text('お気に入りのデッキがありません'),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: _favoriteDecks.length,
      itemBuilder: (context, index) {
        // DeckListTabと同様のデッキ表示
        return Container(); // 簡略化のため空のコンテナを返す
      },
    );
  }
  
}