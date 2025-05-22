// lib/services/sample_data_service.dart
import '../models/card/base_card.dart';
import '../models/card/member_card.dart';
import '../models/card/live_card.dart';
import '../models/card/energy_card.dart';
import '../models/enums/enums.dart';
import '../models/heart.dart';
import '../models/blade_heart.dart';
import '../services/database_service.dart';

class SampleDataService {
  // サンプルデータを生成
  List<BaseCard> generateSampleCards() {
    final cards = <BaseCard>[];
    
    // メンバーカードのサンプル
    cards.add(MemberCard(
      id: 1,
      cardCode: 'SAMPLE-001-P',
      name: '高坂穂乃果',
      rarity: 'P',
      productSet: 'サンプルパック',
      series: SeriesName.lovelive,
      unit: UnitName.printemps,
      imageUrl: '',
      cost: 2,
      hearts: [
        Heart(color: HeartColor.red),
        Heart(color: HeartColor.red),
      ],
      blades: 3,
      bladeHearts: BladeHeart(quantities: {
        BladeHeartColor.normalYellow: 2,
        BladeHeartColor.utility: 1,
      }),
      effect: '【起動】：次のターンの始めまで、自分のメンバー全員の「ブレード＋１する。」',
    ));
    
    // ライブカードのサンプル
    cards.add(LiveCard(
      id: 2,
      cardCode: 'SAMPLE-002-L',
      name: 'Snow halation',
      rarity: 'L',
      productSet: 'サンプルパック',
      series: SeriesName.lovelive,
      unit: UnitName.bibi,
      imageUrl: '',
      score: 5,
      requiredHearts: [
        Heart(color: HeartColor.red),
        Heart(color: HeartColor.yellow),
        Heart(color: HeartColor.blue),
      ],
      bladeHearts: BladeHeart(quantities: {
        BladeHeartColor.scoreUp: 2,
      }),
      effect: '【ライブ】：このライブの合計スコアに、参加しているメンバーの数×2を追加する。',
    ));
    
    // エネルギーカードのサンプル
    cards.add(EnergyCard(
      id: 3,
      cardCode: 'SAMPLE-003-E',
      name: 'エネルギー',
      rarity: 'E',
      productSet: 'サンプルパック',
      series: SeriesName.lovelive,
      imageUrl: '',
    ));
    
    return cards;
  }
  
  //データベースにサンプルデータを保存
  Future<void> saveSampleDataToDatabase() async {
    final db = DatabaseService();
    final sampleCards = generateSampleCards();
    
    for (var card in sampleCards) {
      await db.saveCard(card);
    }
  }
}