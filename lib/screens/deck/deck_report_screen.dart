import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // グラフライブラリをインポート
import '../../models/deck.dart';
import '../../models/card/member_card.dart';
import '../../models/enums/blade_heart.dart';
import '../../models/enums/heart_color.dart';

class DeckReportScreen extends StatefulWidget {
  final Deck deck;
  
  const DeckReportScreen({super.key, required this.deck});
  
  @override
  _DeckReportScreenState createState() => _DeckReportScreenState();
}

class _DeckReportScreenState extends State<DeckReportScreen> {
  // コスト帯データ
  late Map<String, int> _costDistribution;
  // ハート色ごとの数
  late Map<String, int> _heartColors;
  // 合計ハート数
  late int _totalHearts;
  // ブレード期待値
  late double _bladeExpectation;
  
  @override
  void initState() {
    super.initState();
    _analyzeDesk();
  }
  
  // デッキ分析
  void _analyzeDesk() {
    // コスト分布の計算
    _costDistribution = _calculateCostDistribution();
    
    // ハートカラーの集計
    _heartColors = _calculateHeartColors();
    _totalHearts = _heartColors.values.fold(0, (sum, count) => sum + count);
    
    // ブレード期待値の計算
    _bladeExpectation = _calculateBladeExpectation();
  }
  
  // コスト帯の分布を計算
  Map<String, int> _calculateCostDistribution() {
    // コスト帯の定義
    final Map<String, int> distribution = {
      '1-2コスト': 0,
      '3-4コスト': 0,
      '5-6コスト': 0,
      '7+コスト': 0,
    };
    
    // メインデッキのカードを集計（メンバーカードのみ）
    for (final card in widget.deck.mainDeckCards) {
      if (card is MemberCard) {  // ここで型を確認
        int cost = card.cost;    // メンバーカードにcostプロパティを追加する必要あり
        
        if (cost <= 2) {
          distribution['1-2コスト'] = distribution['1-2コスト']! + 1;
        } else if (cost <= 4) {
          distribution['3-4コスト'] = distribution['3-4コスト']! + 1;
        } else if (cost <= 6) {
          distribution['5-6コスト'] = distribution['5-6コスト']! + 1;
        } else {
          distribution['7+コスト'] = distribution['7+コスト']! + 1;
        }
      }
      // LiveCardとEnergyCardはここでスキップされる
    }
    
    return distribution;
  }
  
  // ハートカラーの分布を計算
  Map<String, int> _calculateHeartColors() {
    final Map<String, int> heartColors = {
      '赤': 0,
      '黄': 0,
      '紫': 0,
      '桃': 0,
      '緑': 0,
      '青': 0,
    };
    
    // メンバーカードのハートを集計
    for (final card in widget.deck.mainDeckCards) {
      if (card is MemberCard) {
        for (final heart in card.hearts) {
          final colorName = heart.color.displayName;
          heartColors[colorName] = (heartColors[colorName] ?? 0) + 1;
        }
      }
    }
    
    return heartColors;
  }
  
  // ブレード期待値を計算
  double _calculateBladeExpectation() {
    int normalBladeHearts = 0;
    int utilityBladeHearts = 0;
    int totalCards = widget.deck.mainDeckSize;
    
    if (totalCards == 0) return 0.0;
    
   // メンバーカードのブレードハートを集計
for (final card in widget.deck.mainDeckCards) {
  if (card is MemberCard) {
    // 各タイプの数量を取得して加算
    normalBladeHearts += card.bladeHearts.quantityOf(BladeHeartType.normal);
    utilityBladeHearts += card.bladeHearts.quantityOf(BladeHeartType.utility);
  }
}
    
    // ブレード期待値 = (通常ブレードハート + ユーティリティブレードハート) / カード枚数
    return (normalBladeHearts + utilityBladeHearts) / totalCards;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('デッキレポート'),
        backgroundColor: Color(0xFFE4007F), // ラブライブピンク
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // デッキ情報ヘッダー
            _buildDeckHeader(),
            
            SizedBox(height: 24),
            
            // コスト分布セクション
            _buildSectionTitle('コスト分布'),
            _buildCostDistributionChart(),
            
            SizedBox(height: 32),
            
            // ハート分析セクション
            _buildSectionTitle('ハート分析'),
            _buildHeartAnalysisSection(),
            
            SizedBox(height: 32),
            
            // ブレード期待値
            _buildSectionTitle('ブレード期待値'),
            _buildBladeExpectationSection(),
            
            SizedBox(height: 24),
            
            // デッキ有効性判定
            _buildDeckValiditySection(),
          ],
        ),
      ),
    );
  }
  
  // デッキ基本情報ヘッダー
  Widget _buildDeckHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.deck.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  label: 'メインデッキ',
                  value: '${widget.deck.mainDeckSize}枚',
                  color: Colors.blue,
                ),
                SizedBox(width: 8),
                _buildInfoChip(
                  label: 'メンバー',
                  value: '${widget.deck.memberCardCount}枚',
                  color: Colors.indigo,
                ),
                SizedBox(width: 8),
                _buildInfoChip(
                  label: 'ライブ',
                  value: '${widget.deck.liveCardCount}枚',
                  color: Colors.purple,
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildInfoChip(
              label: 'エネルギーデッキ',
              value: '${widget.deck.energyDeckSize}枚',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
  
  // 情報チップウィジェット
  Widget _buildInfoChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  // セクションタイトル
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE4007F),
        ),
      ),
    );
  }
  
  // コスト分布のチャート
  Widget _buildCostDistributionChart() {
    // グラフのデータ準備
    List<PieChartSectionData> sections = [];
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red];
    int i = 0;
    
    _costDistribution.forEach((range, count) {
      if (count > 0) {
        sections.add(
          PieChartSectionData(
            value: count.toDouble(),
            title: '$range\n$count枚',
            color: colors[i % colors.length],
            radius: 100,
            titleStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      }
      i++;
    });
    
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          SizedBox(height: 16),
          // 凡例
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(_costDistribution.length, (index) {
              final entry = _costDistribution.entries.elementAt(index);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${entry.key}: ${entry.value}枚',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
  
  // ハート分析セクション
  Widget _buildHeartAnalysisSection() {
    // ハートカラーマップの定義
    final heartColorMap = {
      '赤': Colors.red,
      '黄': Colors.amber,
      '紫': Colors.purple,
      'ピンク': Colors.pink,
      '緑': Colors.green,
      '青': Colors.blue,
      '不定色': Colors.grey,
    };
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  '合計ハート数: $_totalHearts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'ハートカラー分布:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _heartColors.entries.map((entry) {
                final color = heartColorMap[entry.key] ?? Colors.grey;
                final count = entry.value;
                
                if (count == 0) return SizedBox.shrink();
                
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    '${entry.key}: $count',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            // ハートグラフ（任意）
            SizedBox(
              height: 100,
              child: Row(
                children: _heartColors.entries.map((entry) {
                  final color = heartColorMap[entry.key] ?? Colors.grey;
                  final count = entry.value;
                  final percentage = _totalHearts > 0 
                      ? count / _totalHearts 
                      : 0.0;
                  
                  if (count == 0) return SizedBox.shrink();
                  
                  return Expanded(
                    flex: count,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${(percentage * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ブレード期待値セクション
  Widget _buildBladeExpectationSection() {
    // ブレード期待値を百分率で表示（例：0.75 → 75%）
    final percentage = (_bladeExpectation * 100).toStringAsFixed(1);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'デッキ全体のブレード期待値は、1枚あたり平均して通常ブレードとユーティリティブレードの合計の期待値を表します。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFE4007F), Colors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$percentage%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // ブレード期待値の評価（任意の追加機能）
            _buildBladeExpectationEvaluation(),
          ],
        ),
      ),
    );
  }
  
  // ブレード期待値の評価
  Widget _buildBladeExpectationEvaluation() {
    String evaluationText;
    Color evaluationColor;
    
    // 期待値に基づく評価
    if (_bladeExpectation >= 0.8) {
      evaluationText = '非常に高い - 攻撃的なデッキ構成です';
      evaluationColor = Colors.green;
    } else if (_bladeExpectation >= 0.5) {
      evaluationText = '高い - バランスの取れたデッキ構成です';
      evaluationColor = Colors.blue;
    } else if (_bladeExpectation >= 0.3) {
      evaluationText = '普通 - 一般的なデッキ構成です';
      evaluationColor = Colors.amber;
    } else {
      evaluationText = '低い - 防御的なデッキ構成です';
      evaluationColor = Colors.red;
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: evaluationColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: evaluationColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '評価: ${evaluationText.split(' - ')[0]}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: evaluationColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            evaluationText.split(' - ')[1],
            style: TextStyle(
              color: evaluationColor,
            ),
          ),
        ],
      ),
    );
  }
  
  // デッキ有効性セクション
  Widget _buildDeckValiditySection() {
    final isValid = widget.deck.isValid();
    final validityColor = isValid ? Colors.green : Colors.red;
    final validityText = isValid 
        ? 'このデッキは有効です。ゲームで使用できます。'
        : 'このデッキは無効です。ゲームで使用するには必要な枚数を調整してください。';
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: validityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: validityColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.warning,
            color: validityColor,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              validityText,
              style: TextStyle(
                color: validityColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}