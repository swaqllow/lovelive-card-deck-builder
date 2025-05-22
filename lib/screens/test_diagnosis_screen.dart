// lib/screens/test_diagnosis_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TestDiagnosisScreen extends StatefulWidget {
  const TestDiagnosisScreen({super.key});

  @override
  _TestDiagnosisScreenState createState() => _TestDiagnosisScreenState();
}

class _TestDiagnosisScreenState extends State<TestDiagnosisScreen> {
  final _cardNumberController = TextEditingController(text: 'PL!N-bp1-002-P');
  String _diagnosis = '';
  bool _isLoading = false;
  
  Future<void> _diagnoseConnection() async {
    setState(() {
      _isLoading = true;
      _diagnosis = '接続診断中...\n\n';
    });
    
    try {
      // 1. インターネット接続の確認
      try {
        final googleResponse = await http.get(Uri.parse('https://www.google.com'));
        _addDiagnosis('✓ インターネット接続: 正常 (${googleResponse.statusCode})');
      } catch (e) {
        _addDiagnosis('✗ インターネット接続: 失敗 ($e)');
        return;
      }
      
      // 2. ラブライブ公式サイトへの接続確認
      try {
        final officialResponse = await http.get(Uri.parse('https://llofficial-cardgame.com/'));
        _addDiagnosis('✓ 公式サイト接続: 正常 (${officialResponse.statusCode})');
      } catch (e) {
        _addDiagnosis('✗ 公式サイト接続: 失敗 ($e)');
        return;
      }
      
      // 3. カード番号のURLエンコーディング確認
      final cardNumber = _cardNumberController.text;
      final encodedNumber = Uri.encodeComponent(cardNumber);
      _addDiagnosis('カード番号: $cardNumber');
      _addDiagnosis('エンコード後: $encodedNumber');
      
      // 4. 実際のカードページへのアクセス
      final cardUrl = 'https://llofficial-cardgame.com/cardlist/searchresults/?cardno=$encodedNumber';
      _addDiagnosis('\nカードURL: $cardUrl');
      
      try {
        final cardResponse = await http.get(Uri.parse(cardUrl));
        _addDiagnosis('✓ カードページ接続: 正常 (${cardResponse.statusCode})');
        
        // 5. レスポンスヘッダーの確認
        _addDiagnosis('\nレスポンスヘッダー:');
        cardResponse.headers.forEach((key, value) {
          _addDiagnosis('  $key: $value');
        });
        
        // 6. レスポンスボディの一部確認
        final body = utf8.decode(cardResponse.bodyBytes);
        _addDiagnosis('\nレスポンス内容（最初の500文字）:');
        _addDiagnosis(body.substring(0, body.length > 500 ? 500 : body.length));
        
        // 7. 重要な要素の存在確認
        _addDiagnosis('\n要素の存在確認:');
        if (body.contains('no-results')) {
          _addDiagnosis('✗ カードが見つかりません');
        } else {
          _addDiagnosis('✓ カード情報がある可能性があります');
        }
        
      } catch (e) {
        _addDiagnosis('✗ カードページアクセス失敗: $e');
      }
      
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _addDiagnosis(String message) {
    setState(() {
      _diagnosis += '$message\n';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('スクレイピング診断'),
        backgroundColor: Color(0xFFE4007F),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // カード番号入力
            TextField(
              controller: _cardNumberController,
              decoration: InputDecoration(
                labelText: 'テスト用カード番号',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            
            // 診断実行ボタン
            ElevatedButton(
              onPressed: _isLoading ? null : _diagnoseConnection,
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('診断中...'),
                      ],
                    )
                  : Text('接続診断を実行'),
            ),
            SizedBox(height: 16),
            
            // 診断結果表示
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _diagnosis.isEmpty ? '診断ボタンを押してください' : _diagnosis,
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _cardNumberController.dispose();
    super.dispose();
  }
}