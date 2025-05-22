// lib/screens/html_structure_viewer.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'dart:convert';

class HtmlStructureViewer extends StatefulWidget {
  const HtmlStructureViewer({super.key});

  @override
  _HtmlStructureViewerState createState() => _HtmlStructureViewerState();
}

class _HtmlStructureViewerState extends State<HtmlStructureViewer> {
  final _urlController = TextEditingController(
    text: 'https://llofficial-cardgame.com/cardlist/searchresults/?cardno=PL!N-bp1-002-P'
  );
  String _htmlContent = '';
  String _structureInfo = '';
  bool _isLoading = false;
  
  Future<void> _fetchAndAnalyzeHtml() async {
    setState(() {
      _isLoading = true;
      _htmlContent = '';
      _structureInfo = '';
    });
    
    try {
      final response = await http.get(Uri.parse(_urlController.text));
      
      if (response.statusCode != 200) {
        setState(() {
          _structureInfo = 'エラー: ステータスコード ${response.statusCode}';
        });
        return;
      }
      
      // レスポンスのエンコーディング確認
      final encoding = response.headers['content-type']?.contains('charset=') == true
          ? response.headers['content-type']!.split('charset=').last
          : 'utf-8';
      
      setState(() {
        _htmlContent = response.body;
      });
      
      // HTMLパースと構造解析
      final document = html_parser.parse(utf8.decode(response.bodyBytes));
      
      var structureInfo = '=== HTML構造解析 ===\n\n';
      
      // 1. 基本情報
      structureInfo += '1. 基本情報\n';
      final titleElement = document.querySelector('title');
      structureInfo += '  title要素: ${titleElement?.text ?? "なし"}\n';
      structureInfo += '  レスポンスサイズ: ${response.bodyBytes.length} bytes\n';
      structureInfo += '  エンコーディング: $encoding\n\n';
      
      // 2. 重要なセレクターのチェック
      structureInfo += '2. カード情報関連要素\n';
      final importantSelectors = [
        'title',
        '.card-name', '.card-title', '.detail-name', '.card-detail-name',
        '.card-type', '.card-category', '.detail-type',
        '.no-results', '.no-result', '.not-found',
        '.card-detail-table', '.detail-table', '.card-info-table',
        '.card-image', '.detail-image', '.main-image',
      ];
      
      for (var selector in importantSelectors) {
        final elements = document.querySelectorAll(selector);
        if (elements.isNotEmpty) {
          structureInfo += '  $selector: ${elements.length}個見つかりました\n';
          // 最初の要素のテキストを表示
          if (elements.first.text.isNotEmpty) {
            structureInfo += '    テキスト: "${elements.first.text.trim()}"\n';
          }
          // 要素のクラス属性を表示
          final classAttr = elements.first.attributes['class'];
          if (classAttr != null) {
            structureInfo += '    クラス: "$classAttr"\n';
          }
        } else {
          structureInfo += '  $selector: 見つかりません\n';
        }
      }
      
      // 3. bodyタグ内の主要な要素構造
      structureInfo += '\n3. body内の主要な要素\n';
      final bodyChildren = document.body?.children ?? [];
      for (var child in bodyChildren.take(10)) {
        structureInfo += '  - <${child.localName}> ';
        if (child.attributes.containsKey('class')) {
          structureInfo += 'class="${child.attributes['class']}"';
        }
        if (child.attributes.containsKey('id')) {
          structureInfo += ' id="${child.attributes['id']}"';
        }
        structureInfo += '\n';
      }
      
      // 4. カード情報を含みそうな要素の詳細
      structureInfo += '\n4. カード情報を含みそうな要素の詳細\n';
      final potentialCardContainers = document.querySelectorAll(
        '[class*="card"], [class*="detail"], [class*="info"], [id*="card"], [id*="detail"]'
      );
      
      for (var element in potentialCardContainers.take(5)) {
        structureInfo += '  要素: <${element.localName}>\n';
        if (element.attributes.containsKey('class')) {
          structureInfo += '    クラス: "${element.attributes['class']}"\n';
        }
        if (element.attributes.containsKey('id')) {
          structureInfo += '    ID: "${element.attributes['id']}"\n';
        }
        structureInfo += '    テキスト（100文字まで）: "${element.text.trim().substring(0, element.text.trim().length > 100 ? 100 : element.text.trim().length)}..."\n';
        structureInfo += '\n';
      }
      
      setState(() {
        _structureInfo = structureInfo;
      });
      
    } catch (e, stackTrace) {
      setState(() {
        _structureInfo = 'エラー: $e\n\nスタックトレース:\n$stackTrace';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HTML構造解析'),
        backgroundColor: Color(0xFFE4007F),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // URL入力
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            
            // 解析実行ボタン
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchAndAnalyzeHtml,
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
                        Text('解析中...'),
                      ],
                    )
                  : Text('HTML構造を解析'),
            ),
            SizedBox(height: 16),
            
            // タブで結果を表示
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      tabs: [
                        Tab(text: '構造解析結果'),
                        Tab(text: '生HTML'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // 構造解析結果
                          SingleChildScrollView(
                            padding: EdgeInsets.all(8),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                _structureInfo.isEmpty ? '解析ボタンを押してください' : _structureInfo,
                                style: TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                          ),
                          
                          // 生HTML
                          SingleChildScrollView(
                            padding: EdgeInsets.all(8),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                _htmlContent.isEmpty ? 'HTMLコンテンツがありません' : _htmlContent,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}