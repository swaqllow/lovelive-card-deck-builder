import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';

import '../models/card/base_card.dart';
import '../models/card/member_card.dart';
import '../models/card/live_card.dart';
import '../models/card/energy_card.dart';
import '../models/enums/heart_color.dart';
import '../models/enums/blade_heart.dart';
import '../models/heart.dart';
import '../models/blade_heart.dart';
import '../models/enums/series_name.dart';
import '../models/enums/unit_name.dart';

class CardScraperService {
  Future<BaseCard?> scrapeCard(String cardNo) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = 'https://llofficial-cardgame.com/cardlist/detail/?t=$timestamp';
      
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'ja,en-US;q=0.7,en;q=0.3',
        'X-Requested-With': 'XMLHttpRequest',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': 'https://llofficial-cardgame.com/cardlist/searchresults/?cardno=$cardNo',
      };
      
      final body = 'cardno=${Uri.encodeComponent(cardNo)}';
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 200) {
        print('=== レスポンス詳細分析 ===');
        print('レスポンス長さ: ${response.body.length}');
        
        final document = parser.parse(response.body);
        
        // メインの抽出処理
        return _extractCardData(document, cardNo);
      }
      
    } catch (e) {
      print('スクレイピングエラー: $e');
    }
    
    return null;
  }

  /// 指定されたパラメータに基づいてカード番号リストを生成する
Future<List<String>> generateCardNumbers({
  required List<String> targetSeries,  // シリーズ識別子 (PL!N, PL!S など)
  required List<String> targetPacks,   // パック識別子 (bp1, pb1 など)
  required List<int> numRange,         // 番号範囲 [最小値, 最大値]
  required List<String> targetRarities, // レアリティ (P, SR, R など)
}) async {
  final List<String> cardNumbers = [];
  
  // 範囲チェック
  if (numRange.length != 2 || numRange[0] > numRange[1]) {
    throw ArgumentError('不正な番号範囲: $numRange');
  }
  
  // 各組み合わせでカード番号を生成
  for (final series in targetSeries) {
    for (final pack in targetPacks) {
      for (int num = numRange[0]; num <= numRange[1]; num++) {
        for (final rarity in targetRarities) {
          // カード番号形式: シリーズ-パック-番号3桁-レアリティ
          final formattedNum = num.toString().padLeft(3, '0');
          final cardNumber = '$series-$pack-$formattedNum-$rarity';
          cardNumbers.add(cardNumber);
        }
      }
    }
  }
  
  return cardNumbers;
}
  
  // 修正版カード情報抽出メソッド
  BaseCard? _extractCardData(Document document, String cardNo) {
    try {
      print('=== カード情報抽出開始 ===');
      
      // カード名の取得（正しいセレクタを使用）
      String cardName = '';
      final namePatterns = [
        'p.info-Heading',    // 調査で判明した正しいセレクタ
        '.info-heading',
        '.cardlist-Info h1',
        '.info-Item h1',
      ];
      
      for (final pattern in namePatterns) {
        final element = document.querySelector(pattern);
        if (element != null && element.text.trim().isNotEmpty) {
          cardName = element.text.trim();
          print('カード名発見 ($pattern): $cardName');
          break;
        }
      }
      
      if (cardName.isEmpty) {
        print('カード名が見つかりません');
        return null;
      }
      
      // 基本情報の抽出
      final infoMap = <String, String>{};
      
      // 変数をメソッドスコープで宣言
      int cost = 0;
      List<Heart> hearts = [];
      BladeHeart bladeHeart = BladeHeart(quantities: {});
      BladeHeart specialHeart = BladeHeart(quantities: {});
      int blade = 0;
      int score = 0;
      String rarity = '';
      String cardType = '';
      SeriesName? seriesName;
      UnitName? unit;
      String productSet = '';

      // DL要素からの情報抽出
      final infoDls = document.querySelectorAll('.info-Dl');
      print('info-Dl要素数: ${infoDls.length}');
      
      for (final dl in infoDls) {
        final items = dl.querySelectorAll('.dl-Item');
        
        for (var item in items) {
          final dt = item.querySelector('dt span, dt');
          final dd = item.querySelector('dd');
          
          if (dt != null && dd != null) {
            final key = dt.text.trim();
            final value = dd.text.trim();
            infoMap[key] = value;
            print('$key: $value');
            
            switch (key) {
              case 'コスト':
                cost = int.tryParse(value) ?? 0;
                break;
                
              case '基本ハート':
                hearts = _extractHearts(dd);
                break;
                
              case 'ブレードハート':
                bladeHeart = _extractBladeHearts(dd);
                break;
              
              case '特殊ハート':
                specialHeart = _extractBladeHearts(dd);
                break;

              case 'スコア':
                score = int.tryParse(value) ?? 0;
                break;

              case 'ブレード':
                blade = int.tryParse(value) ?? 0;
                break;
                
              case 'レアリティ':
                rarity = value;
                break;
                
              case 'カード番号':
                // 確認用（cardNoパラメータと同じはず）
                print('カード番号確認: $value');
                break;
                
              case 'カードタイプ':
                if (value.contains('メンバー')) {
                  cardType = 'member';
                } else if (value.contains('ライブ')) {
                  cardType = 'live';
                } else if (value.contains('エネルギー')) {
                  cardType = 'energy';
                }
                print('カードタイプ: $cardType');
                break;
                
              case '作品名':
                seriesName = _parseSeriesName(value);
                print('シリーズ: $seriesName');
                break;
                
              case '参加ユニット':
                unit = _parseUnitName(value);
                print('ユニット: $unit');
                break;

              case '収録商品':
                productSet = value;
                break;
            }
          }
        }
      }

      // 画像URLの抽出
      String imageUrl = '';
      final imageSelectors = [
        '.image img',
        '.info-Image img',
      ];
      
      for (final selector in imageSelectors) {
        final imageElement = document.querySelector(selector);
        if (imageElement != null) {
          final src = imageElement.attributes['src'];
          if (src != null) {
            imageUrl = src.startsWith('http') ? src : 'https://llofficial-cardgame.com$src';
            print('画像URL発見 ($selector): $imageUrl');
            break;
          }
        }
      }
      
      // 効果文の抽出
      String effect = '';
      final effectElement = document.querySelector('p.info-Text');
      if (effectElement != null) {
        effect = effectElement.text.trim();
        print('効果文: $effect');
      }
      
      // 結果の確認
      print('=== 抽出結果 ===');
      print('カード名: $cardName');
      print('カード番号: $cardNo');
      print('画像URL: $imageUrl');
      print('カードタイプ: $cardType');
      print('レアリティ: $rarity');
      print('シリーズ: $seriesName');
      print('ユニット: $unit');
      print('効果文: ${effect.isNotEmpty ? "あり" : "なし"}');

      // カードタイプに応じた処理
      switch (cardType) {
        case 'member':
          return _createMemberCard(
            cardNo: cardNo,
            name: cardName,
            rarity: rarity,
            productSet: productSet,
            series: seriesName ?? SeriesName.lovelive,
            unit: unit,
            imageUrl: imageUrl,
            cost: cost,
            hearts: hearts,
            bladeHearts: bladeHeart,
            blades: blade,
            infoMap: infoMap,
            document: document,
          );
          
        case 'live':
          return _createLiveCard(
            cardNo: cardNo,
            name: cardName,
            rarity: rarity,
            productSet: productSet,
            series: seriesName ?? SeriesName.lovelive,
            unit: unit,
            imageUrl: imageUrl,
            heart: hearts,
            bladeHeart: bladeHeart,
            specialHeart: specialHeart,
            score: score,
            infoMap: infoMap,
            document: document,
          );
          
        case 'energy':
          return _createEnergyCard(
            cardNo: cardNo,
            name: cardName,
            rarity: rarity,
            productSet: productSet,
            series: seriesName ?? SeriesName.lovelive,
            unit: unit,
            imageUrl: imageUrl,
            infoMap: infoMap,
          );
          
        default:
          print('不明なカードタイプ: $cardType');
          return null;
      }
      
    } catch (e) {
      print('カード情報抽出エラー: $e');
      print('スタックトレース: $e');
      return null;
    }
  }
  
  // メンバーカード作成
  MemberCard _createMemberCard({
    required String cardNo,
    required String name,
    required String rarity,
    required String productSet,
    required SeriesName series,
    UnitName? unit,
    required int cost,
    required List<Heart> hearts,
    required BladeHeart bladeHearts,
    required int blades,
    required String imageUrl,
    required Map<String, String> infoMap,
    required Document document,
  }) {
    // 効果テキストの抽出
    final effect = _extractEffectText(document, infoMap);
    
    print('=== MemberCard作成 ===');
    print('キャラクター: $name');
    print('コスト: $cost');
    print('ブレード: $blades');
    
    return MemberCard(
      id: 0,
      cardCode: cardNo,
      rarity: rarity,
      productSet: productSet,
      name: name,
      series: series,
      unit: unit,
      imageUrl: imageUrl,
      cost: cost,
      hearts: hearts,
      blades: blades,
      bladeHearts: bladeHearts,
      effect: effect,
    );
  }
  
  // ライブカード作成
  LiveCard _createLiveCard({
    required String cardNo,
    required String name,
    required String rarity,
    required String productSet,
    required SeriesName series,
    UnitName? unit,
    required String imageUrl,
    required List<Heart> heart,
    required BladeHeart bladeHeart,
    required BladeHeart specialHeart,
    required int score,
    required Map<String, String> infoMap,
    required Document document,
  }) {
    // ブレードハートの合算処理
    final totalQuantities = <BladeHeartColor, int>{};

    // 通常のブレードハートを追加
    bladeHeart.quantities.forEach((color, quantity) {
      totalQuantities[color] = (totalQuantities[color] ?? 0) + quantity;
    });

    // 特殊ブレードハートを追加
    specialHeart.quantities.forEach((color, quantity) {
      totalQuantities[color] = (totalQuantities[color] ?? 0) + quantity;
    });

    // BladeHeartオブジェクトに変換
    final totalBladeHearts = BladeHeart(quantities: totalQuantities);

    // 効果テキストの抽出
    final effect = _extractEffectText(document, infoMap);
    
    print('=== LiveCard作成 ===');
    print('ライブ名: $name');
    print('スコア: $score');
    
    return LiveCard(
      id: 0,
      cardCode: cardNo,
      rarity: rarity,
      productSet: productSet,
      name: name,
      series: series,
      unit: unit,
      imageUrl: imageUrl,
      score: score,
      requiredHearts: heart,
      bladeHearts: totalBladeHearts,
      effect: effect,
    );
  }
  
  // エネルギーカード作成
  EnergyCard _createEnergyCard({
    required String cardNo,
    required String name,
    required String rarity,
    required String productSet,
    required SeriesName series,
    UnitName? unit,
    required String imageUrl,
    required Map<String, String> infoMap,
  }) {
    print('=== EnergyCard作成 ===');
    print('エネルギー: $name');
    
    return EnergyCard(
      id: 0,
      cardCode: cardNo,
      rarity: rarity,
      productSet: productSet,
      name: name,
      series: series,
      unit: unit,
      imageUrl: imageUrl,
    );
  }
  
  // ハート情報の抽出
  List<Heart> _extractHearts(Element dd) {
    List<Heart> hearts = [];
  
    final heartSpans = dd.querySelectorAll('span[class^="icon heart"]');
    
    for (final span in heartSpans) {
      final className = span.className;
      final count = int.tryParse(span.text.trim()) ?? 0;
      
      HeartColor heartColor = HeartColor.any;
      if (className.contains('heart01')) heartColor = HeartColor.pink;
      if (className.contains('heart02')) heartColor = HeartColor.red;
      if (className.contains('heart03')) heartColor = HeartColor.yellow;
      if (className.contains('heart04')) heartColor = HeartColor.green;
      if (className.contains('heart05')) heartColor = HeartColor.blue;
      if (className.contains('heart06')) heartColor = HeartColor.purple;
      
      for (int i = 0; i < count; i++) {
        hearts.add(Heart(color: heartColor));
      }
    }
    
    return hearts;
  }
  
  // ブレードハート情報の抽出
  BladeHeart _extractBladeHearts(Element dd) {
    Map<BladeHeartColor, int> quantities = {};
    
    final bladeHeartSpan = dd.querySelector('span[class^="icon b_heart"]');
    if (bladeHeartSpan != null) {
      final className = bladeHeartSpan.className;
      if (className.contains('heart01')) quantities[BladeHeartColor.normalPink] = 1;
      if (className.contains('heart02')) quantities[BladeHeartColor.normalRed] = 1;
      if (className.contains('heart03')) quantities[BladeHeartColor.normalYellow] = 1;  
      if (className.contains('heart04')) quantities[BladeHeartColor.normalGreen] = 1;
      if (className.contains('heart05')) quantities[BladeHeartColor.normalBlue] = 1;
      if (className.contains('heart06')) quantities[BladeHeartColor.normalPurple] = 1;
    }
    
    final images = dd.querySelectorAll('img');
    for (final img in images) {
      final altText = img.attributes['alt'] ?? '';
      if (altText.isNotEmpty) {
        if (altText.contains("ALL")) quantities[BladeHeartColor.utility] = 1;
        if (altText.contains("スコア")) quantities[BladeHeartColor.scoreUp] = 1;
        if (altText.contains("ドロー")) quantities[BladeHeartColor.draw] = 1;
      }
    }
    
    return BladeHeart(quantities: quantities);
  }

  // 効果テキストの抽出
  String _extractEffectText(Document document, Map<String, String> infoMap) {
    final effectElement = document.querySelector('p.info-Text');
    if (effectElement != null) {
      final effectText = effectElement.text.trim();
      if (effectText.isNotEmpty) {
        return effectText;
      }
    }
    
    return '';
  }
  
  // シリーズ名の解析
  SeriesName _parseSeriesName(String text) {
    return SeriesName.fromJapaneseName(text);
  }
  
  // ユニット名の解析
  UnitName? _parseUnitName(String text) {
    if (text.isEmpty) return null;
    
    final unitMap = {
      'QU4RTZ': UnitName.qu4rtz,
      'A・ZU・NA': UnitName.azuna,
      'DiverDiva': UnitName.diverdiva,
      'R3BIRTH': UnitName.r3birth,
      // 他のユニットも追加
    };
    
    for (var entry in unitMap.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return null;
  }
}