import 'package:flutter/material.dart';
import '../../models/deck.dart';
import '../../services/database/database_helper.dart';
import 'deck_view_screen.dart';
import 'deck_metadata_screen.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  _DeckListScreenState createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  List<Deck> _decks = [];
  bool _isLoading = true;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  @override
  void initState() {
    super.initState();
    _loadDecks();
  }
  
  Future<void> _loadDecks() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final decks = await _dbHelper.getDecks();
      setState(() {
        _decks = decks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('デッキの読み込みに失敗しました: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('デッキ一覧'),
        backgroundColor: Color(0xFFE4007F), // ラブライブピンク
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _decks.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  itemCount: _decks.length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final deck = _decks[index];
                    final totalCards = deck.mainDeckSize + deck.energyDeckSize;
                    
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        deck.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text('合計: $totalCards枚'),
                              SizedBox(width: 8),
                              Container(
                                width: 1,
                                height: 12,
                                color: Colors.grey[300],
                              ),
                              SizedBox(width: 8),
                              Text('メイン: ${deck.mainDeckSize}枚'),
                              SizedBox(width: 8),
                              Container(
                                width: 1,
                                height: 12,
                                color: Colors.grey[300],
                              ),
                              SizedBox(width: 8),
                              Text('エネルギー: ${deck.energyDeckSize}枚'),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                deck.isValid() 
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color: deck.isValid() 
                                    ? Colors.green
                                    : Colors.amber,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                deck.isValid() ? '有効なデッキ' : '無効なデッキ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: deck.isValid() 
                                      ? Colors.green
                                      : Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeckViewScreen(deck: deck),
                          ),
                        ).then((_) => _loadDecks());
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFE4007F), // ラブライブピンク
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeckMetadataScreen(isNewDeck: true),
            ),
          ).then((_) => _loadDecks());
        },
        child: Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'デッキがありません',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            '右下の "+" ボタンから新しいデッキを作成しましょう',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE4007F), // ラブライブピンク
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeckMetadataScreen(isNewDeck: true),
                ),
              ).then((_) => _loadDecks());
            },
            child: Text('デッキを作成'),
          ),
        ],
      ),
    );
  }
}