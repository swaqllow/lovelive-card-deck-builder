import 'package:flutter/material.dart';
import '../../models/deck.dart';
import '../../services/database/database_helper.dart';
import 'deck_recipe_edit_screen.dart';

class DeckMetadataScreen extends StatefulWidget {
  final bool isNewDeck;
  final Deck? deck;
  
  const DeckMetadataScreen({
    super.key,
    required this.isNewDeck,
    this.deck,
  });
  
  @override
  _DeckMetadataScreenState createState() => _DeckMetadataScreenState();
}

class _DeckMetadataScreenState extends State<DeckMetadataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    
    if (!widget.isNewDeck && widget.deck != null) {
      _nameController.text = widget.deck!.name;
      _notesController.text = widget.deck!.notes;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNewDeck ? 'デッキ新規作成' : 'デッキ情報編集'),
        backgroundColor: Color(0xFFE4007F), // ラブライブピンク
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
                  onPressed: _saveDeck,
                  tooltip: '保存',
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // デッキ名入力
              Text(
                'デッキ名',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'デッキ名を入力してください',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.folder),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'デッキ名を入力してください';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 24),
              
              // デッキメモ入力
              Text(
                'メモ（オプション）',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'デッキに関するメモを記入できます',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 5,
              ),
              
              SizedBox(height: 32),
              
              // 保存ボタン
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE4007F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveDeck,
                  child: Text(
                    '保存',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              if (widget.isNewDeck) ...[
                SizedBox(height: 24),
                
                // 情報パネル
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'デッキの作成について',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'デッキはメインデッキ（メンバーカード48枚とライブカード12枚）とエネルギーデッキ（エネルギーカード12枚）で構成されます。',
                        style: TextStyle(
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '保存後にカードを追加することができます。',
                        style: TextStyle(
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _saveDeck() async {
    if (_isSaving) return;
    
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final newDeckName = _nameController.text.trim();
      final newNotes = _notesController.text.trim();
      
      if (widget.isNewDeck) {
        // 新規デッキの作成
        final newDeck = Deck(
          name: newDeckName,
          mainDeckCards: [],
          energyDeckCards: [],
          notes: newNotes,
        );
        
        final deckId = await _dbHelper.insertDeck(newDeck);
        
        if (deckId != null) {
          // デッキレシピ編集画面へ遷移
          newDeck.id = deckId;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('デッキを作成しました')),
          );
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DeckRecipeEditScreen(deck: newDeck),
            ),
          );
        }
      } else if (widget.deck != null) {
        // 既存デッキの更新
        final updatedDeck = Deck(
          id: widget.deck!.id,
          name: newDeckName,
          mainDeckCards: widget.deck!.mainDeckCards,
          energyDeckCards: widget.deck!.energyDeckCards,
          notes: newNotes,
        );
        
        await _dbHelper.updateDeck(updatedDeck);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('デッキ情報を更新しました')),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}